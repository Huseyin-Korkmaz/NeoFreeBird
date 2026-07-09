//
//  BHTSettings.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Core/BHTSettings.h"
#import "Core/BHTManager.h"
#import "Core/BHTBundle.h"

static NSDictionary<NSString *, NSDictionary *> *BHTSettingsPages(void) {
    static NSDictionary<NSString *, NSDictionary *> *pages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pages = @{
            @"general": @{
                @"titleKey": @"MODERN_SETTINGS_LAYOUT_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_LAYOUT_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"padlock", @"default": @NO },
                    @{ @"key": @"hide_who_to_follow", @"default": @YES },
                    @{ @"key": @"hide_spaces", @"default": @NO },
                    @{ @"key": @"hide_custom_timelines", @"default": @NO },
                    @{ @"key": @"no_tab_bar_hiding", @"default": @YES },
                    @{ @"key": @"tab_bar_theming", @"default": @NO },
                    @{ @"key": @"restore_tab_labels", @"default": @NO },
                    @{ @"key": @"disable_rtl", @"default": @NO },
                    @{ @"key": @"show_scroll_indicator", @"default": @NO },
                    @{ @"key": @"custom_fonts", @"default": @NO },
                    @{ @"type": @"compactButton", @"parentKey": @"custom_fonts", @"key": @"regular_font_button", @"titleKey": @"REQULAR_FONTS_PICKER_OPTION_TITLE", @"action": @"showRegularFontPicker:", @"prefKeyForSubtitle": @"bhtwitter_font_1", @"subtitleDefaultKey": @"FONT_SYSTEM_DEFAULT_SUBTITLE" },
                    @{ @"type": @"compactButton", @"parentKey": @"custom_fonts", @"key": @"bold_font_button", @"titleKey": @"BOLD_FONTS_PICKER_OPTION_TITLE", @"action": @"showBoldFontPicker:", @"prefKeyForSubtitle": @"bhtwitter_font_2", @"subtitleDefaultKey": @"FONT_SYSTEM_DEFAULT_SUBTITLE" }
                ]
            },
            @"twitter_blue": @{
                @"titleKey": @"MODERN_SETTINGS_TWITTER_BLUE_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_TWITTER_BLUE_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"undo_tweet", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_promoted", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_premium_offer", @"default": @YES, @"type": @"toggle" },
                    @{ @"titleKey": @"THEME_OPTION_TITLE", @"action": @"showThemeViewController:", @"type": @"button" },
                    @{ @"titleKey": @"APP_ICON_TITLE", @"action": @"showBHAppIconViewController:", @"type": @"button" },
                    @{ @"titleKey": @"CUSTOM_TAB_BAR_OPTION_TITLE", @"action": @"showCustomTabBarVC:", @"type": @"button" }
                ]
            },
            @"media_downloads": @{
                @"titleKey": @"MODERN_SETTINGS_MEDIA_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_MEDIA_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"download_videos", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"direct_save", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"disable_video_captions", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"auto_highest_load", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"force_tweet_full_frame", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"restore_video_timestamp", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"profiles": @{
                @"titleKey": @"MODERN_SETTINGS_PROFILES_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_PROFILES_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"follow_confirm", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"copy_profile_info", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"bio_translate", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"disable_media_tab", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"disable_articles", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"disable_highlights", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_follow_button", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"restore_follow_button", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"square_avatars", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"tweets": @{
                @"titleKey": @"MODERN_SETTINGS_TWEETS_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_TWEETS_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"tweet_to_image", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"like_confirm", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"tweet_confirm", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_blue_verified", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_view_count", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_bookmark_button", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_downvote_button", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"disable_sensitive_tweet_warnings", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"bypass_age_verification", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_grok_analyze", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"reply_sorting", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"restore_reply_context", @"default": @YES, @"type": @"toggle" }
                ]
            },
            @"search": @{
                @"titleKey": @"MODERN_SETTINGS_SEARCH_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_SEARCH_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"no_history", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_trends", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_trend_videos", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"branding": @{
                @"titleKey": @"MODERN_SETTINGS_BRANDING_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_BRANDING_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"restore_twitter_names", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle" },
                    @{ @"key": @"refresh_pill_label", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle" },
                    @{ @"key": @"color_twitter_icon_in_top_bar", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle" }
                ]
            },
            @"experimental": @{
                @"titleKey": @"MODERN_SETTINGS_EXPERIMENTAL_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_EXPERIMENTAL_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"restore_tweet_labels", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"reply_in_webview", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"web": @{
                @"titleKey": @"MODERN_SETTINGS_WEB_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_WEB_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"strip_tracking_params", @"default": @NO },
                    @{ @"type": @"compactButton", @"parentKey": @"strip_tracking_params", @"key": @"url_host_button", @"titleKey": @"SELECT_URL_HOST_AFTER_COPY_OPTION_TITLE", @"action": @"showURLHostSelectionViewController:", @"prefKeyForSubtitle": @"tweet_url_host", @"subtitleDefault": @"x.com" },
                    @{ @"key": @"always_open_safari", @"default": @NO },
                    @{ @"key": @"new_inapp_webview", @"default": @YES }
                ]
            },
            @"debug": @{
                @"titleKey": @"MODERN_SETTINGS_DEBUG_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_DEBUG_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"flex_twitter", @"default": @NO, @"type": @"toggle" }
                ]
            }
        };
    });
    return pages;
}

static NSDictionary<NSString *, NSDictionary *> *BHTSettingsIndex(void) {
    static NSDictionary<NSString *, NSDictionary *> *index;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSString *, NSDictionary *> *map = [NSMutableDictionary dictionary];
        for (NSDictionary *page in BHTSettingsPages().allValues) {
            for (NSDictionary *setting in page[@"settings"]) {
                NSString *key = setting[@"key"];
                if (key) {
                    map[key] = setting;
                }
            }
        }
        index = [map copy];
    });
    return index;
}

@implementation BHTSettings

// One-time migration of preferences saved under the old (inconsistent) key
// names to the normalised keys, so existing installs keep their settings.
+ (void)load {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"nfb_key_migration_v1_done"]) {
        return;
    }

    NSDictionary<NSString *, NSString *> *renamedKeys = @{
        @"dis_rtl": @"disable_rtl",
        @"showScollIndicator": @"show_scroll_indicator",
        @"en_font": @"custom_fonts",
        @"dw_v": @"download_videos",
        @"video_layer_caption": @"disable_video_captions",
        @"autoHighestLoad": @"auto_highest_load",
        @"follow_con": @"follow_confirm",
        @"CopyProfileInfo": @"copy_profile_info",
        @"disableMediaTab": @"disable_media_tab",
        @"disableArticles": @"disable_articles",
        @"disableHighlights": @"disable_highlights",
        @"TweetToImage": @"tweet_to_image",
        @"like_con": @"like_confirm",
        @"tweet_con": @"tweet_confirm",
        @"disableSensitiveTweetWarnings": @"disable_sensitive_tweet_warnings",
        @"no_his": @"no_history",
        @"openInBrowser": @"always_open_safari",
        @"reply_sorting_enabled": @"reply_sorting",
        @"ios_in_app_article_webview_enabled": @"new_inapp_webview",
    };

    // These old names double as Twitter's own feature-switch keys, so copy the
    // value across but leave the original in place rather than risk removing it.
    NSSet<NSString *> *sharedWithTwitter = [NSSet setWithArray:@[
        @"reply_sorting_enabled",
        @"ios_in_app_article_webview_enabled",
    ]];

    [renamedKeys enumerateKeysAndObjectsUsingBlock:^(NSString *oldKey, NSString *newKey, BOOL *stop) {
        id value = [defaults objectForKey:oldKey];
        if (value == nil) {
            return;
        }
        if ([defaults objectForKey:newKey] == nil) {
            [defaults setObject:value forKey:newKey];
        }
        if (![sharedWithTwitter containsObject:oldKey]) {
            [defaults removeObjectForKey:oldKey];
        }
    }];

    [defaults setBool:YES forKey:@"nfb_key_migration_v1_done"];
}

+ (NSArray<NSDictionary *> *)settingsForPage:(NSString *)pageKey {
    return pageKey ? BHTSettingsPages()[pageKey][@"settings"] : nil;
}

+ (NSString *)titleKeyForPage:(NSString *)pageKey {
    return pageKey ? BHTSettingsPages()[pageKey][@"titleKey"] : nil;
}

+ (NSString *)subtitleKeyForPage:(NSString *)pageKey {
    return pageKey ? BHTSettingsPages()[pageKey][@"subtitleKey"] : nil;
}

+ (NSDictionary *)settingForKey:(NSString *)key {
    return key ? BHTSettingsIndex()[key] : nil;
}

+ (BOOL)boolForKey:(NSString *)key {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (value != nil) {
        return [value boolValue];
    }
    return [[self settingForKey:key][@"default"] boolValue];
}

@end
