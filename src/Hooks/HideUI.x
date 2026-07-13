//
//  HideUI.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Hide Blue verified checkmark

// The badge builder (TwitterUISwift.UserBadger) reads isBlueVerified off the user
// model through ObjC dispatch and treats nil as unset, so answering nil at the
// model level removes the blue checkmark on every surface while leaving the
// separate legacy/brand/government badge fields (verified, identityType) intact.
// TFNTwitterUser and TFNTwitterCanonicalUser forward here and need no hooks.

%hook TFSTwitterUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

%end

// Reaches into the wrapped user's storage directly instead of through its getter.
%hook TFSTwitterUserSource

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

%end

%hook TFSTwitterTypeaheadUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

%end

%hook TFSDirectMessageUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

%end

// Status view models cache the flag as a Swift stored property at init, so the
// user model hooks don't reach consumers of this adapter.
%hook T1TwitterCoreStatusViewModelAdapter

- (BOOL)isFromUserBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// MARK: No search history

// Every recent-search write funnels through _tse_setRecentSearch: and every read
// through recentSearches, so these two cover both saving and display without
// touching the separate saved-searches feature.

%hook TTSRecentSearchesDatastore

- (void)_tse_setRecentSearch:(__unsafe_unretained id)item {
    if (![BHTSettings boolForKey:@"no_history"]) {
        %orig;
    }
}

- (NSArray *)recentSearches {
    return [BHTSettings boolForKey:@"no_history"] ? @[] : %orig;
}

%end

// MARK: Hide trending content on the Explore tab

// The search bar is a direct subview of the container; all trending content
// (page tabs and timelines) lives in the child URT chrome view controller.
// The chrome property has no ObjC getter in 12.3, so find it among the
// children that viewDidLoad adds. The page tab strip is separate: the
// navigation bar requests it through tfn_navigationBarAccessoryView.

%hook _TtC14T1TwitterSwift28GuideContainerViewController

- (void)viewDidLoad {
    %orig;

    if ([BHTSettings boolForKey:@"hide_trends"]) {
        for (UIViewController *child in [(UIViewController *)self childViewControllers]) {
            if ([child isKindOfClass:%c(_TtC14T1TwitterSwift23URTChromeViewController)]) {
                child.view.hidden = YES;
            }
        }
    }
}

- (UIView *)tfn_navigationBarAccessoryView {
    return [BHTSettings boolForKey:@"hide_trends"] ? nil : %orig;
}

%end

// MARK: Hide Grok Analyze button

// The analyze button (timeline author view and post detail nav bar) is gated by a
// per-tweet boolean the API returns via the includeGrokAnalysisButton request
// field. Both shouldShowGrokAnalyzeButtonForAuthorView and
// shouldShowGrokAnalyzeButtonForPostDetailNavBar ultimately return this flag, so
// reporting it as absent at the model level suppresses the button on every
// surface without any view-level hiding or navigation-context guessing.

%hook TFNTwitterCanonicalStatus

- (BOOL)grokAnalysisButton {
    return [BHTSettings boolForKey:@"hide_grok_analyze"] ? NO : %orig;
}

%end

%hook TFSTwitterStatus

- (BOOL)grokAnalysisButton {
    return [BHTSettings boolForKey:@"hide_grok_analyze"] ? NO : %orig;
}

%end

// MARK: No Subscribe button

// The author view's layout delegate has a dedicated show-decision for the
// Subscribe button, so the button never gets created or laid out.

%hook TTAStatusAuthorViewLayoutDelegate

- (BOOL)_t1_shouldShowSubscribeButtonForViewModel:(__unsafe_unretained id)viewModel displayType:(long long)displayType account:(__unsafe_unretained id)account options:(unsigned long long)options {
    return [BHTSettings boolForKey:@"restore_follow_button"] ? NO : %orig;
}

%end

// The control's variant is a bitmask: bit 1 is the Subscribe styling (it
// suppresses the Follow title) and 0x20 is the plain Follow variant, so swap
// the former for the latter. The variant enters through both the initializer
// and setVariant:, and the initializer writes the ivar directly, so both need
// the remap. Do NOT force the variant getter — it made every control report
// Follow regardless of the real relationship and hid the button (NeoFreeBird#2).
static NSUInteger BHTFollowVariantRemovingSubscribe(NSUInteger variant) {
    if ([BHTSettings boolForKey:@"restore_follow_button"] && (variant & 1)) {
        return (variant & ~1) | 0x20;
    }
    return variant;
}

%hook TUIFollowControl

- (id)initWithFollowControlType:(NSUInteger)type variant:(NSUInteger)variant {
    return %orig(type, BHTFollowVariantRemovingSubscribe(variant));
}

- (void)setVariant:(NSUInteger)variant {
    %orig(BHTFollowVariantRemovingSubscribe(variant));
}

%end

// MARK: Hide Follow button on Tweets

// The conversation focal tweet and the immersive player both render their author
// row through TTAStatusAuthorView, which only creates its follow control when
// un-hidden, so forcing the flag covers every surface.

%hook TTAStatusAuthorView

- (void)setFollowControlHidden:(BOOL)hidden {
    %orig([BHTSettings boolForKey:@"hide_follow_button"] ? YES : hidden);
}

%end

// MARK: Hide inline action buttons

%hook TTAStatusInlineActionsView

+ (NSArray *)_t1_inlineActionViewClassesForViewModel:(id)arg1 options:(NSUInteger)arg2 displayType:(NSUInteger)arg3 account:(id)arg4 {
    NSArray *origClasses = %orig;
    if (![origClasses isKindOfClass:NSArray.class]) {
        return origClasses;
    }

    NSMutableArray *newClasses = [origClasses mutableCopy];

    Class analyticsButtonClass = %c(TTAStatusInlineAnalyticsButton);
    if (analyticsButtonClass && [BHTSettings boolForKey:@"hide_view_count"]) {
        [newClasses removeObject:analyticsButtonClass];
    }

    Class bookmarkButtonClass = %c(TTAStatusInlineBookmarkButton);
    if (bookmarkButtonClass && [BHTSettings boolForKey:@"hide_bookmark_button"]) {
        [newClasses removeObject:bookmarkButtonClass];
    }

    Class downvoteButtonClass = %c(TTAStatusInlineDownvoteButton);
    if (downvoteButtonClass && [BHTSettings boolForKey:@"hide_downvote_button"]) {
        [newClasses removeObject:downvoteButtonClass];
    }

    return [newClasses copy];
}

%end
