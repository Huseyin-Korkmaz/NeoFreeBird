//
//  TweetsSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/TweetsSettingsViewController.h"

@implementation TweetsSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_TWEETS_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_TWEETS_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{ @"key": @"TweetToImage", @"titleKey": @"TWEET_TO_IMAGE_OPTION_TITLE", @"subtitleKey": @"TWEET_TO_IMAGE_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"like_con", @"titleKey": @"LIKE_CONFIRM_OPTION_TITLE", @"subtitleKey": @"LIKE_CONFIRM_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"tweet_con", @"titleKey": @"TWEET_CONFIRM_OPTION_TITLE", @"subtitleKey": @"TWEET_CONFIRM_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"hide_blue_verified", @"titleKey": @"HIDE_BLUE_VERIFIED_OPTION_TITLE", @"subtitleKey": @"HIDE_BLUE_VERIFIED_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"hide_view_count", @"titleKey": @"HIDE_VIEW_COUNT_OPTION_TITLE", @"subtitleKey": @"HIDE_VIEW_COUNT_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"hide_bookmark_button", @"titleKey": @"HIDE_MARKBOOK_BUTTON_OPTION_TITLE", @"subtitleKey": @"HIDE_MARKBOOK_BUTTON_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"hide_downvote_button", @"titleKey": @"HIDE_DOWNVOTE_BUTTON_OPTION_TITLE", @"subtitleKey": @"HIDE_DOWNVOTE_BUTTON_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"disableSensitiveTweetWarnings", @"titleKey": @"DISABLE_SENSITIVE_TWEET_WARNINGS_OPTION_TITLE", @"subtitleKey": @"", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"bypass_age_verification", @"titleKey": @"BYPASS_AGE_VERIFICATION_OPTION_TITLE", @"subtitleKey": @"BYPASS_AGE_VERIFICATION_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"hide_grok_analyze", @"titleKey": @"HIDE_GROK_ANALYZE_BUTTON_TITLE", @"subtitleKey": @"HIDE_GROK_ANALYZE_BUTTON_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"reply_sorting_enabled", @"titleKey": @"REPLY_SORTING_TITLE", @"subtitleKey": @"REPLY_SORTING_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"restore_reply_context", @"titleKey": @"RESTORE_REPLY_CONTEXT_TITLE", @"subtitleKey": @"RESTORE_REPLY_CONTEXT_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" }
    ];
}

@end
