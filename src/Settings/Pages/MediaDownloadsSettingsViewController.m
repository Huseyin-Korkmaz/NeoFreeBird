//
//  MediaDownloadsSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/MediaDownloadsSettingsViewController.h"

@implementation MediaDownloadsSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_MEDIA_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_MEDIA_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{ @"key": @"dw_v", @"titleKey": @"DOWNLOAD_VIDEOS_OPTION_TITLE", @"subtitleKey": @"DOWNLOAD_VIDEOS_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"direct_save", @"titleKey": @"DIRECT_SAVE_OPTION_TITLE", @"subtitleKey": @"DIRECT_SAVE_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"video_layer_caption", @"titleKey": @"DISABLE_VIDEO_LAYER_CAPTIONS_OPTION_TITLE", @"subtitleKey": @"", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"autoHighestLoad", @"titleKey": @"AUTO_HIGHEST_LOAD_OPTION_TITLE", @"subtitleKey": @"AUTO_HIGHEST_LOAD_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"force_tweet_full_frame", @"titleKey": @"FORCE_TWEET_FULL_FRAME_TITLE", @"subtitleKey": @"", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"restore_video_timestamp", @"titleKey": @"RESTORE_VIDEO_TIMESTAMP_TITLE", @"subtitleKey": @"RESTORE_VIDEO_TIMESTAMP_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
    ];
}

@end
