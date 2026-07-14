//
//  HideUI.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: - Hide Blue verified checkmark

// The author-row badge (SimpleBadgeable.init(statusViewModel:)) builds from the
// merged verified flag plus identityType and ignores isBlueVerified, so both
// getters must be silenced; brand/government badges survive via identityType.
// TFNTwitterUser and TFNTwitterCanonicalUser forward here and need no hooks.

%hook TFSTwitterUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// Reaches into the wrapped user's storage directly instead of through its getter.
%hook TFSTwitterUserSource

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

%hook TFSTwitterTypeaheadUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

%hook TFSDirectMessageUser

- (id)isBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? nil : %orig;
}

- (BOOL)verified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// Status view models cache these flags at init, beyond the user model hooks; the
// author row badge reads isFromUserVerified, and other view models forward here.
%hook T1TwitterCoreStatusViewModelAdapter

- (BOOL)isFromUserBlueVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

- (BOOL)isFromUserVerified {
    return [BHTSettings boolForKey:@"hide_blue_verified"] ? NO : %orig;
}

%end

// MARK: - No search history

// Every recent-search write funnels through _tse_setRecentSearch: and every read
// through recentSearches; the separate saved-searches feature stays untouched.

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

// MARK: - Hide trending content on the Explore tab

// Trending content lives in the child URT chrome view controller, whose property
// has no ObjC getter in 12.3, so find it among the children. The page tab strip
// arrives separately through tfn_navigationBarAccessoryView.

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

// MARK: - No Subscribe button

// The author view's layout delegate has a dedicated show-decision for the
// Subscribe button, so the button never gets created or laid out.

%hook TTAStatusAuthorViewLayoutDelegate

- (BOOL)_t1_shouldShowSubscribeButtonForViewModel:(__unsafe_unretained id)viewModel displayType:(long long)displayType account:(__unsafe_unretained id)account options:(unsigned long long)options {
    return [BHTSettings boolForKey:@"restore_follow_button"] ? NO : %orig;
}

%end

// The variant is a bitmask: bit 1 is the Subscribe styling, 0x20 the plain
// Follow variant. The initializer writes the ivar directly, so setVariant:
// alone isn't enough. Do NOT force the variant getter — it made every control
// report Follow and hid the button (NeoFreeBird#2).
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

// MARK: - Hide Follow button on Tweets

// The conversation focal tweet and the immersive player both render their author
// row through TTAStatusAuthorView, so forcing the flag here covers every surface.

%hook TTAStatusAuthorView

- (void)setFollowControlHidden:(BOOL)hidden {
    %orig([BHTSettings boolForKey:@"hide_follow_button"] ? YES : hidden);
}

%end

// MARK: - Hide inline action buttons

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
