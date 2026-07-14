//
//  Confirmations.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static void BHTShowConfirmation(void (^confirmed)(void)) {
    [%c(FLEXAlert) makeAlert:^(FLEXAlert *make) {
        make.message([[BHTBundle sharedBundle] localizedStringForKey:@"CONFIRM_ALERT_MESSAGE"]);
        make.button([[BHTBundle sharedBundle] localizedTwitterStringForKey:@"YES_ACTION_LABEL"]).handler(^(NSArray<NSString *> *strings) {
            confirmed();
        });
        make.button([[BHTBundle sharedBundle] localizedTwitterStringForKey:@"NO_ACTION_LABEL"]).cancelStyle();
    } showFrom:topMostController()];
}

// MARK: - Tweet confirm

// All send paths funnel through this. Some callers send no argument, so the
// button register can hold garbage and must not be retained.
%hook T1TweetComposeViewController

- (void)_t1_didTapSendButton:(__unsafe_unretained UIButton *)sendButton {
    if (![BHTSettings boolForKey:@"tweet_confirm"]) {
        return %orig;
    }

    BHTShowConfirmation(^{
        %orig;
    });
}

%end

// MARK: - Follow confirm

%hook TUIFollowControl

- (void)_followUser:(id)sender event:(id)event {
    if (![BHTSettings boolForKey:@"follow_confirm"]) {
        return %orig;
    }

    BHTShowConfirmation(^{
        %orig;
    });
}

%end

// MARK: - Like confirm

// didTap on every inline action button routes through this delegate method,
// so only intercept the favorite button.
%hook TTAStatusInlineActionsView

- (void)didTapInlineActionButton:(UIView *)button {
    if (![BHTSettings boolForKey:@"like_confirm"] || ![button isKindOfClass:%c(TTAStatusInlineFavoriteButton)]) {
        return %orig;
    }

    BHTShowConfirmation(^{
        %orig;
    });
}

%end

// The fullscreen media viewer's heart has its own action path.
%hook T1SlideshowStatusView

- (void)_favoriteAction:(id)sender {
    if (![BHTSettings boolForKey:@"like_confirm"]) {
        return %orig;
    }

    BHTShowConfirmation(^{
        %orig;
    });
}

%end

// Double tap to like in the immersive video player; the gesture never unlikes.
%hook _TtC14T1TwitterSwift32ImmersiveDoubleTapLikePluginView

- (void)handleDoubleTap:(id)gesture {
    if (![BHTSettings boolForKey:@"like_confirm"]) {
        return %orig;
    }

    BHTShowConfirmation(^{
        %orig;
    });
}

%end

// MARK: - Undo tweet

// A timeout of 0 disables undo; any positive value is the delay in seconds.
static BOOL BHTUndoTweetEnabled(void) {
    return [BHTSettings integerForKey:@"undo_tweet_timeout"] > 0;
}

// Force every composition onto the premium undo path (outbox timer, no cap) —
// the free path is just a toast, capped at 10s. Forcing config access and the
// per-type toggles marks it undoable; the forced undoTimeInterval becomes the
// real send delay.
%hook T1UndoSendConfig

- (BOOL)hasAccessToUndoSend {
    return BHTUndoTweetEnabled() ? YES : %orig;
}

- (double)undoTimeInterval {
    return BHTUndoTweetEnabled() ? (double)[BHTSettings integerForKey:@"undo_tweet_timeout"] : %orig;
}

- (BOOL)isUndoSendTurnedOnForOriginalTweets {
    return BHTUndoTweetEnabled() ? YES : %orig;
}

- (BOOL)isUndoSendTurnedOnForReplyTweets {
    return BHTUndoTweetEnabled() ? YES : %orig;
}

- (BOOL)isUndoSendTurnedOnForQuoteTweets {
    return BHTUndoTweetEnabled() ? YES : %orig;
}

- (BOOL)isUndoSendTurnedOnForTweetstormTweets {
    return BHTUndoTweetEnabled() ? YES : %orig;
}

- (BOOL)isUndoSendTurnedOnForPollTweets {
    return BHTUndoTweetEnabled() ? YES : %orig;
}

%end

// The composer bakes the config's interval onto the composition; override the
// read too so the coordinator's send timer uses the chosen value.
%hook TFNTwitterComposition

- (double)undoTimeInterval {
    return BHTUndoTweetEnabled() ? (double)[BHTSettings integerForKey:@"undo_tweet_timeout"] : %orig;
}

// The original computes this from the interval directly, bypassing the getter.
- (NSDate *)undoableSendDate {
    if (!BHTUndoTweetEnabled()) {
        return %orig;
    }
    NSDate *added = [self undoableAddedDate];
    return added ? [added dateByAddingTimeInterval:[self undoTimeInterval]] : nil;
}

%end
