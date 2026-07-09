//
//  Timeline.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Hide custom timelines

static void BHTHideHomeAddTabButton(id container) {
    if (![BHTSettings boolForKey:@"hide_custom_timelines"]) {
        return;
    }

    @try {
        UIView *button = [container valueForKey:@"addTabButton"];
        if ([button isKindOfClass:[UIView class]]) {
            button.hidden = YES;
        }
    } @catch (__unused NSException *exception) {

    }
}

// The repository publishes the pinned-timelines list to the home container
// through this single delegate call, so handing it an empty array removes the
// custom tabs without ever touching the persisted server-side state.
%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController

- (void)pinnedTimelinesRepository:(id)repository didChangeWithPinnedTimelineModels:(NSArray *)models {
    if ([BHTSettings boolForKey:@"hide_custom_timelines"]) {
        %orig(repository, @[]);
        return;
    }

    %orig;
}

- (id)tfn_navigationBarAccessoryView {
    id accessoryView = %orig;
    BHTHideHomeAddTabButton(self);
    return accessoryView;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    BHTHideHomeAddTabButton(self);
}

%end

// While hiding, the overridden pinned-tabs feature switches make the app
// compute an empty pinned list; freezing repository writes keeps it from
// being persisted over the user's real tabs.
%hook _TtC32TwitterHomeFeatureImplementation31CachedPinnedTimelinesRepository

- (void)updatePinnedTimelines:(id)timelines {
    if ([BHTSettings boolForKey:@"hide_custom_timelines"]) {
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

// MARK: Remove the "Discover more" section below conversations

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

static BOOL BHTStatusItemHasTreeContext(id item) {
    if (![item respondsToSelector:@selector(conversationTreeContext)]) {
        return NO;
    }

    return [item performSelector:@selector(conversationTreeContext)] != nil;
}

static NSArray *BHTSectionsWithoutDiscoverMore(TFNItemsDataViewController *dataViewController, NSArray *sections) {
    if (!BHTIsInConversationHierarchy(dataViewController)) {
        return sections;
    }

    Class statusItemClass = objc_getClass("T1URTTimelineStatusItemViewModel");
    if (!statusItemClass) {
        return sections;
    }

    BOOL hasConversationSection = NO;
    for (NSArray *section in sections) {
        if (![section isKindOfClass:[NSArray class]]) {
            continue;
        }

        for (id item in section) {
            if ([item isKindOfClass:statusItemClass] && BHTStatusItemHasTreeContext(item)) {
                hasConversationSection = YES;
                break;
            }
        }

        if (hasConversationSection) {
            break;
        }
    }

    if (!hasConversationSection) {
        return sections;
    }

    NSMutableArray *filteredSections = [NSMutableArray arrayWithCapacity:sections.count];

    for (NSArray *section in sections) {
        BOOL hasStatusItems = NO;
        BOOL hasTreeItems = NO;

        if ([section isKindOfClass:[NSArray class]]) {
            for (id item in section) {
                if ([item isKindOfClass:statusItemClass]) {
                    hasStatusItems = YES;
                    if (BHTStatusItemHasTreeContext(item)) {
                        hasTreeItems = YES;
                        break;
                    }
                }
            }
        }

        if (!hasStatusItems || hasTreeItems) {
            [filteredSections addObject:section];
        }
    }

    return filteredSections.count == sections.count ? sections : [filteredSections copy];
}

%hook TFNItemsDataViewController

- (void)setSections:(NSArray *)sections restoreScrollPosition:(BOOL)restoreScrollPosition {
    %orig(BHTSectionsWithoutDiscoverMore(self, sections), restoreScrollPosition);
}

- (void)updateSections:(NSArray *)sections reconfigureItemIdentifiers:(NSArray *)identifiers withRowAnimation:(long long)animation completion:(id)completion {
    %orig(BHTSectionsWithoutDiscoverMore(self, sections), identifiers, animation, completion);
}

%end
