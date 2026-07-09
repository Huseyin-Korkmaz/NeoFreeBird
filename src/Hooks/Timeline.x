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
