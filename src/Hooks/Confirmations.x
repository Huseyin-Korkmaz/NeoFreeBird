//
//  Confirmations.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static void BHTShowConfirmation(void (^confirmed)(void)) {
    [%c(FLEXAlert) makeAlert:^(FLEXAlert *make) {
        make.message([[BHTBundle sharedBundle] localizedStringForKey:@"CONFIRM_ALERT_MESSAGE"]);
        make.button([[BHTBundle sharedBundle] localizedStringForKey:@"YES_BUTTON_TITLE"]).handler(^(NSArray<NSString *> *strings) {
            confirmed();
        });
        make.button([[BHTBundle sharedBundle] localizedStringForKey:@"NO_BUTTON_TITLE"]).cancelStyle();
    } showFrom:topMostController()];
}

// MARK: Tweet confirm

// The toolbar post button, the cmd+return key command and the quick promote
// flow all funnel through this. Some callers send no argument, so the button
// register can hold garbage and must not be retained.
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

// MARK: Follow confirm

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

// MARK: Like confirm

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

// MARK: Undo tweet

%hook TFNTwitterToastNudgeExperimentModel

- (BOOL)shouldShowShowUndoTweetSentToast {
    return [BHTSettings boolForKey:@"undo_tweet"] ? YES : %orig;
}

%end
