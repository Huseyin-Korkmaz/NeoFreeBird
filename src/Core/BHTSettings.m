//
//  BHTSettings.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Core/BHTSettings.h"
#import "Core/BHTManager.h"

static NSDictionary<NSString *, NSDictionary *> *BHTSettingsPages(void) {
    static NSDictionary<NSString *, NSDictionary *> *pages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pages = @{
            @"general": @{
                @"titleKey": @"MODERN_SETTINGS_LAYOUT_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_LAYOUT_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"padlock", @"titleKey": @"PADLOCK_OPTION_TITLE", @"subtitleKey": @"PADLOCK_OPTION_DETAIL_TITLE", @"default": @NO },
                    @{ @"key": @"hide_topics", @"titleKey": @"HIDE_TOPICS_OPTION_TITLE", @"subtitleKey": @"HIDE_TOPICS_OPTION_DETAIL_TITLE", @"default": @YES },
                    @{ @"key": @"hide_topics_to_follow", @"titleKey": @"HIDE_TOPICS_TO_FOLLOW_OPTION", @"subtitleKey": @"HIDE_TOPICS_TO_FOLLOW_OPTION_DETAIL_TITLE", @"default": @YES },
                    @{ @"key": @"hide_who_to_follow", @"titleKey": @"HIDE_WHO_FOLLOW_OPTION", @"subtitleKey": @"HIDE_WHO_FOLLOW_OPTION_DETAIL_TITLE", @"default": @YES },
                    @{ @"key": @"hide_spaces", @"titleKey": @"HIDE_SPACE_OPTION_TITLE", @"subtitleKey": @"", @"default": @NO },
                    @{ @"key": @"hide_custom_timelines", @"titleKey": @"HIDE_CUSTOM_TIMELINES_OPTION_TITLE", @"subtitleKey": @"HIDE_CUSTOM_TIMELINES_OPTION_DETAIL_TITLE", @"default": @NO },
                    @{ @"key": @"no_tab_bar_hiding", @"titleKey": @"STOP_HIDING_TAB_BAR_TITLE", @"subtitleKey": @"STOP_HIDING_TAB_BAR_DETAIL_TITLE", @"default": @YES },
                    @{ @"key": @"tab_bar_theming", @"titleKey": @"CLASSIC_TAB_BAR_SETTINGS_TITLE", @"subtitleKey": @"CLASSIC_TAB_BAR_SETTINGS_DETAIL", @"default": @NO },
                    @{ @"key": @"restore_tab_labels", @"titleKey": @"RESTORE_TAB_LABELS_TITLE", @"subtitleKey": @"RESTORE_TAB_LABELS_DETAIL", @"default": @NO },
                    @{ @"key": @"dis_rtl", @"titleKey": @"DISABLE_RTL_OPTION_TITLE", @"subtitleKey": @"DISABLE_RTL_OPTION_DETAIL_TITLE", @"default": @NO },
                    @{ @"key": @"showScollIndicator", @"titleKey": @"SHOW_SCOLL_INDICATOR_OPTION_TITLE", @"subtitleKey": @"", @"default": @NO },
                    @{ @"key": @"en_font", @"titleKey": @"FONT_OPTION_TITLE", @"subtitleKey": @"FONT_OPTION_DETAIL_TITLE", @"default": @NO },
                    @{ @"type": @"compactButton", @"parentKey": @"en_font", @"key": @"regular_font_button", @"titleKey": @"REQULAR_FONTS_PICKER_OPTION_TITLE", @"action": @"showRegularFontPicker:", @"prefKeyForSubtitle": @"bhtwitter_font_1", @"subtitleDefault": @"System Default" },
                    @{ @"type": @"compactButton", @"parentKey": @"en_font", @"key": @"bold_font_button", @"titleKey": @"BOLD_FONTS_PICKER_OPTION_TITLE", @"action": @"showBoldFontPicker:", @"prefKeyForSubtitle": @"bhtwitter_font_2", @"subtitleDefault": @"System Default" }
                ]
            },
            @"twitter_blue": @{
                @"titleKey": @"MODERN_SETTINGS_TWITTER_BLUE_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_TWITTER_BLUE_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"undo_tweet", @"titleKey": @"UNDO_TWEET_OPTION_TITLE", @"subtitleKey": @"UNDO_TWEET_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_promoted", @"titleKey": @"HIDE_ADS_OPTION_TITLE", @"subtitleKey": @"HIDE_ADS_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_premium_offer", @"titleKey": @"HIDE_PREMIUM_OFFER_OPTION", @"subtitleKey": @"HIDE_PREMIUM_OFFER_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"titleKey": @"THEME_OPTION_TITLE", @"action": @"showThemeViewController:", @"type": @"button" },
                    @{ @"titleKey": @"APP_ICON_TITLE", @"action": @"showBHAppIconViewController:", @"type": @"button" },
                    @{ @"titleKey": @"CUSTOM_TAB_BAR_OPTION_TITLE", @"action": @"showCustomTabBarVC:", @"type": @"button" }
                ]
            },
            @"media_downloads": @{
                @"titleKey": @"MODERN_SETTINGS_MEDIA_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_MEDIA_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"dw_v", @"titleKey": @"DOWNLOAD_VIDEOS_OPTION_TITLE", @"subtitleKey": @"DOWNLOAD_VIDEOS_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"direct_save", @"titleKey": @"DIRECT_SAVE_OPTION_TITLE", @"subtitleKey": @"DIRECT_SAVE_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"video_layer_caption", @"titleKey": @"DISABLE_VIDEO_LAYER_CAPTIONS_OPTION_TITLE", @"subtitleKey": @"", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"autoHighestLoad", @"titleKey": @"AUTO_HIGHEST_LOAD_OPTION_TITLE", @"subtitleKey": @"AUTO_HIGHEST_LOAD_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"force_tweet_full_frame", @"titleKey": @"FORCE_TWEET_FULL_FRAME_TITLE", @"subtitleKey": @"", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"restore_video_timestamp", @"titleKey": @"RESTORE_VIDEO_TIMESTAMP_TITLE", @"subtitleKey": @"RESTORE_VIDEO_TIMESTAMP_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"profiles": @{
                @"titleKey": @"MODERN_SETTINGS_PROFILES_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_PROFILES_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"follow_con", @"titleKey": @"FOLLOW_CONFIRM_OPTION_TITLE", @"subtitleKey": @"FOLLOW_CONFIRM_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"CopyProfileInfo", @"titleKey": @"COPY_PROFILE_INFO_OPTION_TITLE", @"subtitleKey": @"COPY_PROFILE_INFO_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"bio_translate", @"titleKey": @"BIO_TRANSLATE_OPTION_TITLE", @"subtitleKey": @"BIO_TRANSLATE_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"disableMediaTab", @"titleKey": @"DISABLE_MEDIA_TAB_OPTION_TITLE", @"subtitleKey": @"DISABLE_MEDIA_TAB_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"disableArticles", @"titleKey": @"DISABLE_ARTICLES_OPTION_TITLE", @"subtitleKey": @"DISABLE_ARTICLES_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"disableHighlights", @"titleKey": @"DISABLE_HIGHLIGHTS_OPTION_TITLE", @"subtitleKey": @"DISABLE_HIGHLIGHTS_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
                    @{ @"key": @"hide_follow_button", @"titleKey": @"HIDE_FOLLOW_BUTTON_TITLE", @"subtitleKey": @"HIDE_FOLLOW_BUTTON_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"restore_follow_button", @"titleKey": @"RESTORE_FOLLOW_BUTTON_TITLE", @"subtitleKey": @"RESTORE_FOLLOW_BUTTON_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"square_avatars", @"titleKey": @"SQUARE_AVATARS_TITLE", @"subtitleKey": @"SQUARE_AVATARS_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"tweets": @{
                @"titleKey": @"MODERN_SETTINGS_TWEETS_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_TWEETS_SUBTITLE",
                @"settings": @[
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
                ]
            },
            @"search": @{
                @"titleKey": @"MODERN_SETTINGS_SEARCH_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_SEARCH_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"no_his", @"titleKey": @"NO_HISTORY_OPTION_TITLE", @"subtitleKey": @"NO_HISTORY_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_trends", @"titleKey": @"HIDE_TRENDS_OPTION_TITLE", @"subtitleKey": @"HIDE_TRENDS_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"hide_trend_videos", @"titleKey": @"HIDE_TREND_VIDEOS_OPTION_TITLE", @"subtitleKey": @"HIDE_TREND_VIDEOS_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"branding": @{
                @"titleKey": @"MODERN_SETTINGS_BRANDING_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_BRANDING_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"restore_twitter_names", @"titleKey": @"RESTORE_TWITTER_NAMES_OPTION_TITLE", @"subtitleKey": @"RESTORE_TWITTER_NAMES_OPTION_DETAIL_TITLE", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle" },
                    @{ @"key": @"refresh_pill_label", @"titleKey": @"REFRESH_PILL_OPTION_TITLE", @"subtitleKey": @"REFRESH_PILL_DETAIL_TITLE", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle" },
                    @{ @"key": @"color_twitter_icon_in_top_bar", @"titleKey": @"COLOR_TWITTER_ICON_OPTION_TITLE", @"subtitleKey": @"COLOR_TWITTER_ICON_DETAIL_TITLE", @"default": @([BHTManager isTwitterBranded]), @"type": @"toggle" }
                ]
            },
            @"experimental": @{
                @"titleKey": @"MODERN_SETTINGS_EXPERIMENTAL_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_EXPERIMENTAL_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"restore_tweet_labels", @"titleKey": @"ENABLE_TWEET_LABELS_OPTION_TITLE", @"subtitleKey": @"ENABLE_TWEET_LABELS_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
                    @{ @"key": @"reply_in_webview", @"titleKey": @"REPLY_IN_WEBVIEW_OPTION_TITLE", @"subtitleKey": @"REPLY_IN_WEBVIEW_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
                ]
            },
            @"web": @{
                @"titleKey": @"MODERN_SETTINGS_WEB_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_WEB_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"strip_tracking_params", @"titleKey": @"STRIP_URL_TRACKING_PARAMETERS_TITLE", @"subtitleKey": @"STRIP_URL_TRACKING_PARAMETERS_DETAIL_TITLE", @"default": @NO },
                    @{ @"type": @"compactButton", @"parentKey": @"strip_tracking_params", @"key": @"url_host_button", @"titleKey": @"SELECT_URL_HOST_AFTER_COPY_OPTION_TITLE", @"action": @"showURLHostSelectionViewController:", @"prefKeyForSubtitle": @"tweet_url_host", @"subtitleDefault": @"x.com" },
                    @{ @"key": @"openInBrowser", @"titleKey": @"ALWAYS_OPEN_SAFARI_OPTION_TITLE", @"subtitleKey": @"ALWAYS_OPEN_SAFARI_OPTION_DETAIL_TITLE", @"default": @NO },
                    @{ @"key": @"ios_in_app_article_webview_enabled", @"titleKey": @"NEW_INAPP_WEB_OPTION_TITLE", @"subtitleKey": @"NEW_INAPP_WEB_DETAIL_TITLE", @"default": @YES }
                ]
            },
            @"debug": @{
                @"titleKey": @"MODERN_SETTINGS_DEBUG_TITLE",
                @"subtitleKey": @"MODERN_SETTINGS_DEBUG_SUBTITLE",
                @"settings": @[
                    @{ @"key": @"flex_twitter", @"titleKey": @"FLEX_OPTION_TITLE", @"subtitleKey": @"FLEX_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
                ]
            }
        };
    });
    return pages;
}

@implementation BHTSettings

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
    if (!key) {
        return nil;
    }
    for (NSDictionary *page in BHTSettingsPages().allValues) {
        for (NSDictionary *setting in page[@"settings"]) {
            if ([setting[@"key"] isEqualToString:key]) {
                return setting;
            }
        }
    }
    return nil;
}

+ (BOOL)boolForKey:(NSString *)key {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (value != nil) {
        return [value boolValue];
    }
    return [[self settingForKey:key][@"default"] boolValue];
}

@end
