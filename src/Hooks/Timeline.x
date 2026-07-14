//
//  Timeline.x
//  NeoFreeBird
//

#import "HookHelpers.h"

// MARK: - Hide custom timelines

static __weak NSObject *PinnedTimelinesRepository;
static NSArray *LastPinnedTimelineModels;
static BOOL PinnedTimelinesWriteBypass = NO;

// Applies a toggle without relaunching. Hiding rewrites the UNCHANGED pinned
// list purely to republish — updatePinnedTimelines: persists server-side, so
// anything else would unpin for real; the delegate hook below swaps in the
// empty list on the way through.
void applyHideCustomTimelinesSetting(void) {
    NSObject *repository = PinnedTimelinesRepository;
    if (!repository) {
        return;
    }

    if ([BHTSettings boolForKey:@"hide_custom_timelines"]) {
        NSArray *models = LastPinnedTimelineModels;
        if (models.count > 0) {
            PinnedTimelinesWriteBypass = YES;
            ((void (*)(id, SEL, id))objc_msgSend)(repository, @selector(updatePinnedTimelines:), models);
            PinnedTimelinesWriteBypass = NO;
        }
    } else if ([repository respondsToSelector:@selector(fetchPinnedTimelinesWithThrottleEnabled:)]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(repository, @selector(fetchPinnedTimelinesWithThrottleEnabled:), NO);
    }
}

// The trailing accessory is only reconfigured while the strip is showing, so a
// button built before hiding mid-session survives; sync its visibility here. The
// property is a Swift lazy var whose storage ivar KVC can't see, hence the fallback.
static void SyncHomeAddTabButton(id container, BOOL hidden) {
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

// The repository publishes the pinned list through this single delegate call, so
// handing it an empty array hides the tabs without touching persisted state.
%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController

- (void)pinnedTimelinesRepository:(id)repository didChangeWithPinnedTimelineModels:(NSArray *)models {
    PinnedTimelinesRepository = repository;
    if (models.count > 0) {
        LastPinnedTimelineModels = [models copy];
    }
    BOOL hide = [BHTSettings boolForKey:@"hide_custom_timelines"];

    %orig(repository, hide ? @[] : models);
    SyncHomeAddTabButton(self, hide);
}

- (id)tfn_navigationBarAccessoryView {
    id accessoryView = %orig;
    SyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
    return accessoryView;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    SyncHomeAddTabButton(self, [BHTSettings boolForKey:@"hide_custom_timelines"]);
}

%end

// While hiding, the overridden pinned-tabs feature switches make the app compute
// an empty pinned list; freeze writes so it can't overwrite the real tabs.
%hook _TtC32TwitterHomeFeatureImplementation31CachedPinnedTimelinesRepository

- (void)updatePinnedTimelines:(id)timelines {
    if (!PinnedTimelinesWriteBypass && [BHTSettings boolForKey:@"hide_custom_timelines"]) {
        return;
    }

    %orig;
}

%end

// MARK: - Force tweet images to full frame

%hook T1StandardStatusAttachmentViewAdapter

// attachmentType 2 = photos, displayType 1 = full frame
- (NSUInteger)displayType {
    if (self.attachmentType == 2) {
        return [BHTSettings boolForKey:@"force_tweet_full_frame"] ? 1 : %orig;
    }

    return %orig;
}

%end

// MARK: - Hide the Spaces bar

// The bar is still the repurposed Fleets line; both home timeline implementations
// share this visibility gate, re-evaluated on every content or settings update.
%hook T1FleetLineHeaderController

- (BOOL)_t1_shouldShowFleetLine {
    if ([BHTSettings boolForKey:@"hide_spaces"]) {
        return NO;
    }

    return %orig;
}

%end

// MARK: - Hide "Discover more", who-to-follow and prompts

static BOOL IsInConversationHierarchy(UIViewController *viewController) {
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

static NSString *ItemEntryID(id viewModel) {
    if (![viewModel respondsToSelector:@selector(entryID)]) {
        return nil;
    }

    NSString *entryID = [viewModel performSelector:@selector(entryID)];
    return [entryID isKindOfClass:[NSString class]] ? entryID : nil;
}

// Discriminates by entry ID (conversationTreeContext is never populated in 12.3):
// Discover More items carry "tweetdetailrelatedtweets-…" and who-to-follow entries
// "who-to-follow-…". Server-sent prompt banners all render through the one prompt
// view model, so those are matched by class instead.
static BOOL ShouldHideTimelineItem(id item, BOOL hideWhoToFollow, BOOL hidePrompts, BOOL inConversation) {
    id viewModel = unwrapDataViewItem(item);

    if (hidePrompts && [NSStringFromClass([viewModel classForCoder]) isEqualToString:@"TwitterURT.URTTimelinePromptViewModel"]) {
        return YES;
    }

    NSString *entryID = ItemEntryID(viewModel);

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

static NSArray *FilteredTimelineSections(TFNItemsDataViewController *dataViewController, NSArray *sections) {
    BOOL hideWhoToFollow = [BHTSettings boolForKey:@"hide_who_to_follow"];
    BOOL hidePrompts = [BHTSettings boolForKey:@"hide_timeline_prompts"];
    BOOL inConversation = IsInConversationHierarchy(dataViewController);

    if (!hideWhoToFollow && !hidePrompts && !inConversation) {
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
            if (!ShouldHideTimelineItem(item, hideWhoToFollow, hidePrompts, inConversation)) {
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
    %orig(FilteredTimelineSections(self, sections), restoreScrollPosition);
}

- (void)updateSections:(NSArray *)sections reconfigureItemIdentifiers:(NSArray *)identifiers withRowAnimation:(long long)animation completion:(id)completion {
    %orig(FilteredTimelineSections(self, sections), identifiers, animation, completion);
}

%end
