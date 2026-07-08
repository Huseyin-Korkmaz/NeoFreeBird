//
//  HideUI.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Hide Blue verified checkmark

%hook T1CompositionStatusViewModel
- (BOOL)isFromUserVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
- (BOOL)isFromUserBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
%end

%hook TFNTwitterStatus
- (BOOL)isFromUserVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
- (BOOL)isFromUserBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
%end

%hook T1StandardUserViewModel
- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
- (BOOL)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
%end

%hook T1ProfileUserViewModel
- (BOOL)isVerifiedAccount {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
%end

%hook T1TwitterCoreStatusViewModelAdapter
- (BOOL)isFromUserVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
- (BOOL)isFromUserBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}
%end
// MARK: No search history
%hook T1SearchTypeaheadViewController // for old Twitter versions
- (void)viewDidLoad {
    if ([BHTSettings boolForKey:@"no_his"]) { // thanks @CrazyMind90
        if ([self respondsToSelector:@selector(clearActionControlWantsClear:)]) {
            [self performSelector:@selector(clearActionControlWantsClear:)];
        }
    }
    %orig;
}
%end

%hook TTSSearchTypeaheadViewController
- (void)viewDidLoad {
    if ([BHTSettings boolForKey:@"no_his"]) { // thanks @CrazyMind90
        if ([self respondsToSelector:@selector(clearActionControlWantsClear:)]) {
            [self performSelector:@selector(clearActionControlWantsClear:)];
        }
    }
    %orig;
}
%end
// MARK: - Hide the trending/explore content on the Explore tab (keep the search bar)
static void BHT_hideExploreTabBar(UIView *view) {
    if (!view) return;
    if ([view isKindOfClass:NSClassFromString(@"TFNScrollingHorizontalLabelView")]) {
        view.hidden = YES;
        return;
    }
    for (UIView *subview in view.subviews) {
        BHT_hideExploreTabBar(subview);
    }
}

%hook T1GuideNavigationController
- (void)viewDidLayoutSubviews {
    %orig;
    if (![BHTSettings boolForKey:@"hide_trends"]) return;
    @try {
        UINavigationController *nav = (UINavigationController *)self;

        UIViewController *guideVC = nav.viewControllers.firstObject;
        if (!guideVC) return;

        Class chromeClass = NSClassFromString(@"T1TwitterSwift.URTChromeViewController");
        UIViewController *chrome = nil;
        for (UIViewController *child in guideVC.childViewControllers) {
            BOOL isChrome = chromeClass ? [child isKindOfClass:chromeClass]
                                        : [child respondsToSelector:@selector(tfn_navigationBarAccessoryView)];
            if (isChrome) { chrome = child; break; }
        }
        if (!chrome) return;

        if (chrome.isViewLoaded) chrome.view.hidden = YES;

        if ([chrome respondsToSelector:@selector(tfn_navigationBarAccessoryView)]) {
            UIView *accessory = ((UIView *(*)(id, SEL))objc_msgSend)(chrome, @selector(tfn_navigationBarAccessoryView));
            BHT_hideExploreTabBar(accessory);
        }
    } @catch (NSException *exception) {
        NSLog(@"[BHTwitter] hideTrends exception: %@", exception);
    }
}
%end

%hook T1ImmersiveExploreCardView
- (void)handleDoubleTap:(id)arg1 {
    if ([BHTSettings boolForKey:@"like_con"]) {
        [%c(FLEXAlert) makeAlert:^(FLEXAlert *make) {
            make.message([[BHTBundle sharedBundle] localizedStringForKey:@"CONFIRM_ALERT_MESSAGE"]);
            make.button([[BHTBundle sharedBundle] localizedStringForKey:@"YES_BUTTON_TITLE"]).handler(^(NSArray<NSString *> *strings) {
                %orig;
            });
            make.button([[BHTBundle sharedBundle] localizedStringForKey:@"NO_BUTTON_TITLE"]).cancelStyle();
        } showFrom:topMostController()];
    } else {
        return %orig;
    }
}
%end

%hook T1TweetDetailsViewController
- (void)_t1_toggleFavoriteOnCurrentStatus {
    if ([BHTSettings boolForKey:@"like_con"]) {
        [%c(FLEXAlert) makeAlert:^(FLEXAlert *make) {
            make.message([[BHTBundle sharedBundle] localizedStringForKey:@"CONFIRM_ALERT_MESSAGE"]);
            make.button([[BHTBundle sharedBundle] localizedStringForKey:@"YES_BUTTON_TITLE"]).handler(^(NSArray<NSString *> *strings) {
                %orig;
            });
            make.button([[BHTBundle sharedBundle] localizedStringForKey:@"NO_BUTTON_TITLE"]).cancelStyle();
        } showFrom:topMostController()];
    } else {
        return %orig;
    }
}
%end
// MARK: - Hide Grok Analyze Button
// The analyze button (timeline author view and post detail nav bar) is gated by a per-tweet
// boolean the API returns via the includeGrokAnalysisButton request field. Both
// shouldShowGrokAnalyzeButtonForAuthorView and shouldShowGrokAnalyzeButtonForPostDetailNavBar
// ultimately return this flag, so reporting it as absent at the model level suppresses the
// button on every surface without any view-level hiding or navigation-context guessing.
%hook TFNTwitterCanonicalStatus
- (BOOL)grokAnalysisButton {
    if ([BHTSettings boolForKey:@"hide_grok_analyze"]) return NO;
    return %orig;
}
%end

%hook TFSTwitterStatus
- (BOOL)grokAnalysisButton {
    if ([BHTSettings boolForKey:@"hide_grok_analyze"]) return NO;
    return %orig;
}
%end

// MARK: - Hide Subscribe Button on Detail View

// Minimal interface for TFNButton, used by UIControl hook and FollowButton logic
@class TFNButton;

%hook UIControl
// Subscribe button
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    if (action == @selector(_didTapSubscribe)) {
        if ([self isKindOfClass:NSClassFromString(@"TFNButton")] && [BHTSettings boolForKey:@"restore_follow_button"]) {
            self.alpha = 0.0;
            self.userInteractionEnabled = NO;
        }
    }
    %orig(target, action, controlEvents);
}

%end

// MARK: - Hide Follow Button (T1ConversationFocalStatusView)

// Minimal interface for T1ConversationFocalStatusView
@class T1ConversationFocalStatusView;

// Helper function to recursively find and hide a TFNButton by accessibilityIdentifier
static BOOL findAndHideButtonWithAccessibilityId(UIView *viewToSearch, NSString *targetAccessibilityId) {
    @try {
        // Safety check: Ensure view and target are valid
        if (!viewToSearch || !targetAccessibilityId || !viewToSearch.superview) {
            return NO;
        }

        if ([viewToSearch isKindOfClass:NSClassFromString(@"TFNButton")]) {
            TFNButton *button = (TFNButton *)viewToSearch;
            if ([button.accessibilityIdentifier isEqualToString:targetAccessibilityId]) {
                button.hidden = YES;
                return YES;
            }
        }

        // Create a copy of subviews to avoid mutation during iteration
        NSArray *subviews = [viewToSearch.subviews copy];
        for (UIView *subview in subviews) {
            if (findAndHideButtonWithAccessibilityId(subview, targetAccessibilityId)) {
                return YES;
            }
        }
        return NO;
    } @catch (NSException *exception) {
        NSLog(@"[BHTwitter] Exception in findAndHideButtonWithAccessibilityId: %@", exception);
        return NO;
    }
}

%hook T1ConversationFocalStatusView

- (void)didMoveToWindow {
    %orig;
    if ([BHTSettings boolForKey:@"hide_follow_button"]) {
        findAndHideButtonWithAccessibilityId(self, @"FollowButton");
    }
}

%end

// MARK: - Hide Follow Button (T1ImmersiveViewController)

// Minimal interface for T1ImmersiveViewController
@interface T1ImmersiveViewController : UIViewController
@end

%hook T1ImmersiveViewController

- (void)viewDidLoad {
    %orig;
    @try {
        if ([BHTSettings boolForKey:@"hide_follow_button"] && self.view) {
            findAndHideButtonWithAccessibilityId(self.view, @"FollowButton");
        }
    } @catch (NSException *exception) {
        NSLog(@"[BHTwitter] Exception in T1ImmersiveViewController viewDidLoad: %@", exception);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    @try {
        if ([BHTSettings boolForKey:@"hide_follow_button"] && self.view) {
            findAndHideButtonWithAccessibilityId(self.view, @"FollowButton");
        }
    } @catch (NSException *exception) {
        NSLog(@"[BHTwitter] Exception in T1ImmersiveViewController viewWillAppear: %@", exception);
    }
}

%end

// MARK: - Restore Follow Button (TUIFollowControl)

@interface TUIFollowControl : UIControl
- (void)setVariant:(NSUInteger)variant;
- (NSUInteger)variant; // Ensure getter is declared
@end

%hook TUIFollowControl

- (void)setVariant:(NSUInteger)variant {
    if ([BHTSettings boolForKey:@"restore_follow_button"]) {
        NSUInteger subscribeVariantID = 1;
        NSUInteger desiredFollowVariantID = 32;
        if (variant == subscribeVariantID) {
            %orig(desiredFollowVariantID);
        } else {
            %orig(variant);
        }
    } else {
        %orig;
    }
}

// NOTE: We intentionally do NOT override -variant. Forcing it to a constant 32
// made every TUIFollowControl report "Follow" regardless of the real account
// relationship, which hid the Follow button on every tweet (NeoFreeBird#2).
// The setVariant: remap above already converts Subscribe (1) -> Follow (32).

%end
