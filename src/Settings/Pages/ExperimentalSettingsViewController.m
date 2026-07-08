//
//  ExperimentalSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/ExperimentalSettingsViewController.h"

@implementation ExperimentalSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_EXPERIMENTAL_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_EXPERIMENTAL_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{ @"key": @"restore_tweet_labels", @"titleKey": @"ENABLE_TWEET_LABELS_OPTION_TITLE", @"subtitleKey": @"ENABLE_TWEET_LABELS_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"reply_in_webview", @"titleKey": @"REPLY_IN_WEBVIEW_OPTION_TITLE", @"subtitleKey": @"REPLY_IN_WEBVIEW_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
    ];
}

@end
