//
//  Timeline.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Hide custom timelines

static __weak NSObject *BHTPinnedTimelinesRepository;
static NSArray *BHTLastPinnedTimelineModels;
static BOOL BHTPinnedTimelinesWriteBypass = NO;

// Applies a toggle without relaunching. Hiding rewrites the unchanged pinned
// list through the repository — updatePinnedTimelines: is the same write the
// tab reorder uses, so anything but the real list would unpin the user's tabs
// for real. The rewrite only serves to republish: the delegate hook below swaps
// in the empty list on the way through, collapsing the strip.
void BHT_applyHideCustomTimelinesSetting(void) {
    NSObject *repository = BHTPinnedTimelinesRepository;
    if (!repository) {
        return;
    }

    if ([BHTSettings boolForKey:@"hide_custom_timelines"]) {
        NSArray *models = BHTLastPinnedTimelineModels;
        if (models.count > 0) {
            BHTPinnedTimelinesWriteBypass = YES;
            ((void (*)(id, SEL, id))objc_msgSend)(repository, @selector(updatePinnedTimelines:), models);
            BHTPinnedTimelinesWriteBypass = NO;
        }
    } else if ([repository respondsToSelector:@selector(fetchPinnedTimelinesWithThrottleEnabled:)]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(repository, @selector(fetchPinnedTimelinesWithThrottleEnabled:), NO);
    }
}

// The app only reconfigures the tab bar's trailing accessory while the pinned
// tab strip is showing, so a button built before hiding mid-session survives
// (with its tap gated off); its visibility is synced here instead. The property
// is a Swift lazy var, whose storage ivar KVC can't see, hence the fallback.
static void BHTSyncHomeAddTabButton(id container, BOOL hidden) {
    UIView *button = nil;

    @try {
        button = [container valueForKey:@"addTabButton"];
    } @catch (__unused NSException *exception) {
        unsigned int ivarCount = 0;
        Ivar *ivars = class_copyIvarList([container class], &ivarCount);
        for (unsigned int i = 0; i < ivarCount; i++) {
            const char *name = ivar_getName(ivars[i]);
            if (name && strstr(name, "addTabButton")) {
                button = object_getIvar(container, ivars[i]);
                break;
            }
        }
        free(ivars);
    }

    if ([button isKindOfClass:[UIView class]]) {
        button.hidden = hidden;
    }
}

// The repository publishes the pinned-timelines list to the home container
// through this single delegate call, so handing it an empty array removes the
// custom tabs without ever touching the persisted server-side state.
%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController

- (void)pinnedTimelinesRepository:(id)repository didChangeWithPinnedTimelineModels:(NSArray *)models {
    BHTPinnedTimelinesRepository = repository;
    if (models.count > 0) {
        BHTLastPinnedTimelineModels = [models copy];
    }
    BOOL hide = [BHTSettings boolForKey:@"hide_custom_timelines"];

    %orig(repository, hide ? @[] : models);
    BHTSyncHomeAddTabButton(self, hide);
}

- (id)tfn_navigationBarAccessoryView {
    id accessoryView = %orig;
    BHTSyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
    return accessoryView;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    BHTSyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
}

%end

// While hiding, the overridden pinned-tabs feature switches make the app
// compute an empty pinned list; freezing repository writes keeps it from
// being persisted over the user's real tabs.
%hook _TtC32TwitterHomeFeatureImplementation31CachedPinnedTimelinesRepository

- (void)updatePinnedTimelines:(id)timelines {
    if (!BHTPinnedTimelinesWriteBypass && [BHTSettings boolForKey:@"hide_custom_timelines"]) {
        return;
    }

    %orig;
}

%end

// MARK: Force Tweets to show images as Full frame: https://github.com/BandarHL/BHTwitter/issues/101

%hook T1StandardStatusAttachmentViewAdapter

// attachmentType 2 = photos, displayType 1 = full frame
- (NSUInteger)displayType {
    if (self.attachmentType == 2) {
        return [BHTSettings boolForKey:@"force_tweet_full_frame"] ? 1 : %orig;
    }

    return %orig;
}

%end

// MARK: Hide the Spaces bar

// The bar is still the repurposed Fleets line. Both home timeline
// implementations create the same T1FleetLineHeaderController, and this is its
// visibility gate, re-evaluated on every content or settings update.
%hook T1FleetLineHeaderController

- (BOOL)_t1_shouldShowFleetLine {
    if ([BHTSettings boolForKey:@"hide_spaces"]) {
        return NO;
    }

    return %orig;
}

%end

// MARK: Remove the "Discover more" section below conversations and who-to-follow modules

static BOOL BHTIsInConversationHierarchy(UIViewController *viewController) {
    UIViewController *currentVC = viewController;

    while (currentVC) {
        if ([NSStringFromClass([currentVC class]) isEqualToString:@"T1ConversationContainerViewController"]) {
            return YES;
        }

        if (currentVC.parentViewController) {
            currentVC = currentVC.parentViewController;
        } else if (currentVC.navigationController) {
            currentVC = currentVC.navigationController;
        } else if (currentVC.presentingViewController) {
            currentVC = currentVC.presentingViewController;
        } else {
            break;
        }
    }

    return NO;
}

static NSString *BHTItemEntryID(id item) {
    id viewModel = BHT_unwrapDataViewItem(item);

    if (![viewModel respondsToSelector:@selector(entryID)]) {
        return nil;
    }

    NSString *entryID = [viewModel performSelector:@selector(entryID)];
    return [entryID isKindOfClass:[NSString class]] ? entryID : nil;
}

// Both filters discriminate by entry ID (verified on device; the former
// conversationTreeContext discriminator is never populated in 12.3). Discover More
// items carry "tweetdetailrelatedtweets-…", who-to-follow entries "who-to-follow-…",
// while replies are "conversationthread-…" and the focal tweet "tweet-…".
static BOOL BHTShouldHideTimelineItem(id item, BOOL hideWhoToFollow, BOOL inConversation) {
    NSString *entryID = BHTItemEntryID(item);

    if (!entryID) {
        return NO;
    }

    if (inConversation && [entryID hasPrefix:@"tweetdetailrelatedtweets"]) {
        return YES;
    }

    if (hideWhoToFollow && [entryID containsString:@"who-to-follow"]) {
        return YES;
    }

    return NO;
}

static NSArray *BHTFilteredTimelineSections(TFNItemsDataViewController *dataViewController, NSArray *sections) {
    BOOL hideWhoToFollow = [BHTSettings boolForKey:@"hide_who_to_follow"];
    BOOL inConversation = BHTIsInConversationHierarchy(dataViewController);

    if (!hideWhoToFollow && !inConversation) {
        return sections;
    }

    // Modules can share a section with unrelated items, so filtering is per item;
    // a purely filtered section (like the Discover More one) empties and is dropped.
    BOOL modified = NO;
    NSMutableArray *filteredSections = [NSMutableArray arrayWithCapacity:sections.count];

    for (id section in sections) {
        if (![section isKindOfClass:[NSArray class]]) {
            [filteredSections addObject:section];
            continue;
        }

        NSArray *items = section;
        NSMutableArray *keptItems = [NSMutableArray arrayWithCapacity:items.count];

        for (id item in items) {
            if (!BHTShouldHideTimelineItem(item, hideWhoToFollow, inConversation)) {
                [keptItems addObject:item];
            }
        }

        if (keptItems.count == items.count) {
            [filteredSections addObject:section];
            continue;
        }

        modified = YES;
        if (keptItems.count > 0) {
            [filteredSections addObject:keptItems];
        }
    }

    return modified ? [filteredSections copy] : sections;
}

%hook TFNItemsDataViewController

- (void)setSections:(NSArray *)sections restoreScrollPosition:(BOOL)restoreScrollPosition {
    %orig(BHTFilteredTimelineSections(self, sections), restoreScrollPosition);
}

- (void)updateSections:(NSArray *)sections reconfigureItemIdentifiers:(NSArray *)identifiers withRowAnimation:(long long)animation completion:(id)completion {
    %orig(BHTFilteredTimelineSections(self, sections), identifiers, animation, completion);
}

%end
