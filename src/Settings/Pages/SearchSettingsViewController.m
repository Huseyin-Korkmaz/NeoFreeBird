//
//  SearchSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/SearchSettingsViewController.h"

@implementation SearchSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_SEARCH_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_SEARCH_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{ @"key": @"no_his", @"titleKey": @"NO_HISTORY_OPTION_TITLE", @"subtitleKey": @"NO_HISTORY_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"hide_trends", @"titleKey": @"HIDE_TRENDS_OPTION_TITLE", @"subtitleKey": @"HIDE_TRENDS_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"hide_trend_videos", @"titleKey": @"HIDE_TREND_VIDEOS_OPTION_TITLE", @"subtitleKey": @"HIDE_TREND_VIDEOS_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
    ];
}

@end
