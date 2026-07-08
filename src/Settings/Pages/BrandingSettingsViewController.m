//
//  BrandingSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/BrandingSettingsViewController.h"
#import "Core/BHTManager.h"

@implementation BrandingSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_BRANDING_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_BRANDING_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{@"key": @"restore_twitter_names", @"titleKey": @"RESTORE_TWITTER_NAMES_OPTION_TITLE", @"subtitleKey": @"RESTORE_TWITTER_NAMES_OPTION_DETAIL_TITLE", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle"},
        @{@"key": @"refresh_pill_label", @"titleKey": @"REFRESH_PILL_OPTION_TITLE", @"subtitleKey": @"REFRESH_PILL_DETAIL_TITLE", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle"},
        @{@"key": @"color_twitter_icon_in_top_bar", @"titleKey": @"COLOR_TWITTER_ICON_OPTION_TITLE", @"subtitleKey": @"COLOR_TWITTER_ICON_DETAIL_TITLE", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle"}
    ];
}

@end
