//
//  Confirmations.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Tweet confirm
%hook T1TweetComposeViewController
- (void)_t1_didTapSendButton:(UIButton *)tweetButton {
    if ([BHTManager TweetConfirm]) {
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
- (void)_t1_handleTweet {
    if ([BHTManager TweetConfirm]) {
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

// MARK: Follow confirm
%hook TUIFollowControl
- (void)_followUser:(id)arg1 event:(id)arg2 {
    if ([BHTManager FollowConfirm]) {
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

// MARK: Like confirm
%hook TTAStatusInlineFavoriteButton
- (void)didTap {
    if ([BHTManager LikeConfirm]) {
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

%hook T1StatusInlineFavoriteButton
- (void)didTap {
    if ([BHTManager LikeConfirm]) {
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
// MARK: Undo tweet
%hook TFNTwitterToastNudgeExperimentModel
- (BOOL)shouldShowShowUndoTweetSentToast {
    return [BHTManager UndoTweet] ? true : %orig;
}
%end
