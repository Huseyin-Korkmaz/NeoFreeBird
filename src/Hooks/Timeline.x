//
//  Timeline.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"


static NSTimeInterval BHTPinnedTabsLaunchUptime = 0;

static id BHTPinnedTabsPersistenceCoordinator(void) {
    static id coordinator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coordinator = [NSObject new];
    });
    return coordinator;
}

static NSArray *BHTPinnedTimelinesSnapshot(id repository) {
    if (!repository || ![repository respondsToSelector:@selector(pinnedTimelines)]) {
        return nil;
    }
    id value = ((id (*)(id, SEL))objc_msgSend)(repository, @selector(pinnedTimelines));
    return [value isKindOfClass:[NSArray class]] ? value : nil;
}

static void BHTRecordPinnedTimelineUnpin(void) {
    @synchronized (BHTPinnedTabsPersistenceCoordinator()) {
        [[NSUserDefaults standardUserDefaults] setDouble:CFAbsoluteTimeGetCurrent() forKey:@"BHTCustomTimelinesUnpinTime"];
    }
}

%hook _TtC32TwitterHomeFeatureImplementation31CachedPinnedTimelinesRepository
- (void)unpinTimelineWithTimeline:(id)timeline completion:(id)completion {
    BHTRecordPinnedTimelineUnpin();
    %orig;
}

- (void)unpinTimelineWithTimelineInput:(id)input completion:(id)completion {
    BHTRecordPinnedTimelineUnpin();
    %orig;
}

- (void)updatePinnedTimelines:(id)timelines {
    if ([BHTManager hideCustomTimelines]) {
        %orig;
        return;
    }

    BOOL block = NO;
    @synchronized (BHTPinnedTabsPersistenceCoordinator()) {
        BOOL isArray = [timelines isKindOfClass:[NSArray class]];
        NSUInteger incomingCount = isArray ? [timelines count] : 0;
        NSTimeInterval now = CFAbsoluteTimeGetCurrent();
        NSTimeInterval lastUnpin = [[NSUserDefaults standardUserDefaults] doubleForKey:@"BHTCustomTimelinesUnpinTime"];

        if ((now - lastUnpin < 120.0) || (isArray && incomingCount != 0)) {
            block = NO;
        } else {
            NSArray *snapshot = BHTPinnedTimelinesSnapshot(self);
            if (snapshot.count == 0) {
                block = NO;
            } else {
                NSTimeInterval uptime = [[NSProcessInfo processInfo] systemUptime];
                BOOL withinStartupWindow = (BHTPinnedTabsLaunchUptime > 0) && ((uptime - BHTPinnedTabsLaunchUptime) < 20.0);
                block = withinStartupWindow;
            }
        }
    }

    if (!block) {
        %orig;
    }
}
%end

static void BHTHideHomeAddTabButton(id container) {
    if (![BHTManager hideCustomTimelines]) {
        return;
    }
    @try {
        id button = [container valueForKey:@"addTabButton"];
        if ([button isKindOfClass:[UIView class]]) {
            ((UIView *)button).hidden = YES;
        }
    } @catch (__unused NSException *exception) {

		}
}

%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController
- (id)tfn_navigationBarAccessoryView {
    id accessory = %orig;
    BHTHideHomeAddTabButton(self);
    return accessory;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    BHTHideHomeAddTabButton(self);
}
%end

// MARK: Force Tweets to show images as Full frame: https://github.com/BandarHL/BHTwitter/issues/101
%hook T1StandardStatusAttachmentViewAdapter
- (NSUInteger)displayType {
    if (self.attachmentType == 2) {
        return [BHTManager forceTweetFullFrame] ? 1 : %orig;
    }
    return %orig;
}
%end

%hook T1HomeTimelineItemsViewController
- (void)_t1_initializeFleets {
    if ([BHTManager hideSpacesBar]) {
        return;
    }
    return %orig;
}
%end

%hook THFHomeTimelineItemsViewController
- (void)_t1_initializeFleets {
    if ([BHTManager hideSpacesBar]) {
        return;
    }
    return %orig;
}
%end


%hook THFHomeTimelineContainerViewController
- (void)_t1_showPremiumUpsellIfNeeded {
    if ([BHTManager hidePremiumOffer]) {
        return;
    }
    return %orig;
}
- (void)_t1_showPremiumUpsellIfNeededWithScribing:(BOOL)arg1 {
    if ([BHTManager hidePremiumOffer]) {
        return;
    }
    return %orig;
}
%end
// Helper function to check if we're in the T1ConversationContainerViewController hierarchy
static BOOL BHT_isInConversationContainerHierarchy(UIViewController *viewController) {
    if (!viewController) return NO;

    // Check all view controllers up the hierarchy
    UIViewController *currentVC = viewController;
    while (currentVC) {
        NSString *className = NSStringFromClass([currentVC class]);

        // Check for T1ConversationContainerViewController
        if ([className isEqualToString:@"T1ConversationContainerViewController"]) {
            return YES;
        }

        // Move up the hierarchy
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

// MARK : Remove "Discover More" section
%hook T1URTViewController

- (void)setSections:(NSArray *)sections {

    // Only filter if we're in the T1ConversationContainerViewController hierarchy
    BOOL inConversationHierarchy = BHT_isInConversationContainerHierarchy((UIViewController *)self);

    if (inConversationHierarchy) {
        // Remove entry 1 (index 1) from sections array
        if (sections.count > 1) {
            NSMutableArray *filteredSections = [NSMutableArray arrayWithArray:sections];
            [filteredSections removeObjectAtIndex:1];
            sections = [filteredSections copy];
        }
    }

    %orig(sections);
}

%end

%ctor {
    BHTPinnedTabsLaunchUptime = [[NSProcessInfo processInfo] systemUptime];

    %init;
}
