//
//  FeatureSwitches.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static NSNumber *BHTFeatureSwitchOverrideValueForKey(NSString *key) {
    if (![key isKindOfClass:[NSString class]]) {
        return nil;
    }

    // Custom timelines overrides
    BOOL hideCustomTimelines = [BHTSettings boolForKey:@"hide_custom_timelines"];
    if ([key isEqualToString:@"hometimeline_pinned_tabs_topics_enabled"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_generic_timelines_enabled"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_sticky_warm_start_enabled"] ||
        [key isEqualToString:@"super_follow_subscriptions_home_timeline_tab_sticky_enabled"]) {
        return hideCustomTimelines ? @NO : @YES;
    }

    // Keeps the selected timeline tab across sessions.
    if ([key isEqualToString:@"home_timeline_non_sticky_tab_on_new_session_enabled"]) {
        return @NO;
    }

    if ([key isEqualToString:@"hometimeline_pinned_tabs_limit"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_management_pinnedsection_inline_limit"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_management_topics_inline_limit"]) {
        return hideCustomTimelines ? @0 : @100;
    }

    // Edit tweet
    if ([key isEqualToString:@"edit_tweet_ga_composition_enabled"] ||
        [key isEqualToString:@"edit_tweet_pdp_dialog_enabled"]) {
        return @YES;
    }

    // Restore the animated launch screen (AppLifecycle.x strips its X-shaped reveal mask)
    if ([key isEqualToString:@"app_launch_animated_launch_screen_enabled"]) {
        return @YES;
    }

    // Grok translations
    if ([key isEqualToString:@"grok_translations_bio_inline_translation_is_enabled"] ||
        [key isEqualToString:@"grok_translations_bio_translation_is_enabled"] ||
        [key isEqualToString:@"grok_translations_post_inline_translation_is_enabled"] ||
        [key isEqualToString:@"grok_translations_post_translation_is_enabled"]) {
        return @YES;
    }

    // Grok buttons
    if ([key isEqualToString:@"grok_ask_grok_button_under_post_focal_enabled"] ||
        [key isEqualToString:@"grok_ask_grok_button_under_post_preview_enabled"] ||
        [key isEqualToString:@"grok_edit_with_grok_button_under_post_focal_enabled"] ||
        [key isEqualToString:@"grok_edit_with_grok_button_under_post_preview_enabled"] ||
        [key isEqualToString:@"grok_ios_profile_summary_enabled"]) {
        return @YES;
    }

    // Session token appended to shared/copied links (&t=)
    if ([key isEqualToString:@"rehire_share_update_url_enabled"]) {
        return @NO;
    }

    // The profile hooks build on the classic header; the header rework
    // replaces the action-buttons row with a separate catalog system.
    if ([key isEqualToString:@"ios_profile_redesign_header_rework_enabled"]) {
        return @NO;
    }

    // Profile tabs
    if ([key isEqualToString:@"articles_timeline_profile_tab_enabled"]) {
        return @(![BHTSettings boolForKey:@"disable_articles"]);
    }

    if ([key isEqualToString:@"highlights_tweets_tab_ui_enabled"]) {
        return @(![BHTSettings boolForKey:@"disable_highlights"]);
    }

    // Age verification bypass
    if ([key hasPrefix:@"ios_age_assurance"] || [key isEqualToString:@"grok_settings_age_restriction_enabled"]) {
        if ([BHTSettings boolForKey:@"bypass_age_verification"]) {
            return @NO;
        }
    }

    // Conversation / tweet detail
    if ([key isEqualToString:@"reply_sorting_enabled"]) {
        return @(![BHTSettings boolForKey:@"reply_sorting"]);
    }

    if ([key isEqualToString:@"ios_tweet_detail_overflow_in_navigation_enabled"]) {
        return @NO;
    }

    if ([key isEqualToString:@"ios_tweet_detail_conversation_context_removal_enabled"]) {
        return @(![BHTSettings boolForKey:@"restore_reply_context"]);
    }

    // Video captions
    if ([key isEqualToString:@"ios_tav_default_closed_captions_enabled"] ||
        [key isEqualToString:@"ios_audio_transcription_subtitles_vod_enabled"]) {
        return [BHTSettings boolForKey:@"disable_video_captions"] ? @NO : nil;
    }

    // Always build the Profile and Communities tabs so they can be captured and
    // toggled in the tab bar editor; the editor's visible/hidden lists decide
    // whether they actually appear. Grok is likewise force-shown (its read site ORs
    // with the premium tier we force on), and all three are hidden by default in the
    // setTabViews: filter until the user opts in.
    if ([key isEqualToString:@"ios_tab_bar_default_show_profile"] ||
        [key isEqualToString:@"ios_tab_bar_default_show_communities"]) {
        return @YES;
    }

    // In-app article webview
    if ([key isEqualToString:@"ios_in_app_article_webview_enabled"]) {
        return @([BHTSettings boolForKey:@"new_inapp_webview"]);
    }

    // A negative threshold disables immersive auto-advance and removes its row
    // from the player's settings sheet.
    if ([key isEqualToString:@"immersive_video_auto_advance_duration_threshold"]) {
        return [BHTSettings boolForKey:@"disable_immersive_scroll"] ? @(-1) : nil;
    }

    // Reply downvote (dislike) button
    if ([key isEqualToString:@"conversational_replies_ios_downvote_enabled"]) {
        return [BHTSettings boolForKey:@"hide_downvote_button"] ? @NO : nil;
    }

    // Premium features gate on subscriptions_enabled || (gating bypass && premium tier).
    if ([key isEqualToString:@"subscriptions_gating_bypass"]) {
        return @YES;
    }

    // Premium / subscription upsell disables
    if ([key isEqualToString:@"creator_purchases_dashboard_enabled"] ||
        [key isEqualToString:@"subscriptions_settings_item_enabled"] ||
        [key isEqualToString:@"creator_monetization_dashboard_enabled"] ||
        [key isEqualToString:@"creator_monetization_profile_subscription_tweets_tab_enabled"] ||
        [key isEqualToString:@"subscriptions_upsells_get_verified_profile"] ||
        [key isEqualToString:@"ios_profile_analytics_upsell_possible_enabled"] ||
        [key isEqualToString:@"ios_profile_analytics_upsell_enabled"] ||
        [key isEqualToString:@"subscriptions_verification_info_reason_enabled"] ||
        [key isEqualToString:@"subscriptions_verification_info_verified_since_enabled"] ||
        [key isEqualToString:@"communities_enable_explore_tab"] ||
        [key isEqualToString:@"dash_items_download_grok_enabled"]) {
        return @NO;
    }

    return nil;
}

// MARK: Feature switch overrides

// Every feature switch facade (TPSTwitterFeatureSwitches, TFSAccountFeatureSwitches,
// TFSFeatureSwitchesService) bottoms out in per-account TFSFeatureSwitches
// instances, but those can be wrapped in TFSInstrumentedFeatureSwitches, which
// implements its own typed getters, so both classes need the same hooks.

%hook TFSFeatureSwitches

- (BOOL)boolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.boolValue : %orig;
}

- (NSInteger)integerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.integerValue : %orig;
}

- (NSNumber *)numberForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ?: %orig;
}

- (id)rawValueForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ?: %orig;
}

- (BOOL)unsafePeekBoolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.boolValue : %orig;
}

- (NSInteger)unsafePeekIntegerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.integerValue : %orig;
}

// Some reads, like the default captions setup, only consult the value when the
// switch reports a non-default one.
- (BOOL)hasNonDefaultValueForKey:(NSString *)key {
    return BHTFeatureSwitchOverrideValueForKey(key) ? YES : %orig;
}

%end

%hook TFSInstrumentedFeatureSwitches

- (BOOL)boolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.boolValue : %orig;
}

- (NSInteger)integerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.integerValue : %orig;
}

- (NSNumber *)numberForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ?: %orig;
}

- (id)rawValueForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ?: %orig;
}

- (BOOL)unsafePeekBoolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.boolValue : %orig;
}

- (NSInteger)unsafePeekIntegerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    return override ? override.integerValue : %orig;
}

- (BOOL)hasNonDefaultValueForKey:(NSString *)key {
    return BHTFeatureSwitchOverrideValueForKey(key) ? YES : %orig;
}

%end

// MARK: Show Scroll Bar

// The vertical scroll indicator on every TFN data view is set from this typed
// accessor in -[TFNDataViewController loadView]; its read bypasses the
// boolForKey: funnels above via a Swift access-once provider.

%hook TFSAccountFeatureSwitches

+ (BOOL)isShowsVerticalScrollIndicatorEnabled {
    return [BHTSettings boolForKey:@"show_scroll_indicator"] ? YES : %orig;
}

%end

// MARK: Override the login screens

%hook T1AccountsViewController

- (void)private_startLoginFlowWithSender:(id)sender {
    [BHTLegacyLoginViewController presentLoginFrom:(UIViewController *)self];
}

%end

%hook T1HostViewController

- (void)makeOnboardingViewControllerWithCompletion:(void (^)(id))completion {
    if (completion == nil) {
        %orig;
        return;
    }
    completion([BHTLegacyLoginViewController loginRootNavigationController]);
}

%end

// MARK: High quality images

%hook T1ImageDisplayView

- (BOOL)_tfn_shouldUseHighestQualityImage {
    return [BHTSettings boolForKey:@"auto_highest_load"] ? YES : %orig;
}

- (BOOL)_tfn_shouldUseHighQualityImage {
    return [BHTSettings boolForKey:@"auto_highest_load"] ? YES : %orig;
}

%end

// MARK: Promoted content

// API commands copy this off their context when building requests.
%hook TFNTwitterAPICommandContext

- (BOOL)allowPromotedContent {
    return [BHTSettings boolForKey:@"hide_promoted"] ? NO : %orig;
}

%end

// MARK: Account feature gates

%hook TFNTwitterAccount

- (BOOL)canAccessXPayments {
    return YES;
}

// Premium tier state funnels through -isSubscribedTo:, which reads the account's
// subscription claims: isPremiumTierUser checks tiers 0/7/8, isVerifiedPremiumTierUser
// checks 0/8, and isSubscribedToAnyPremiumTier builds on those. Forcing the premium
// tiers here unlocks premium across every account-level check from one stable seam.
- (BOOL)isSubscribedTo:(NSUInteger)tier {
    if (tier == 0 || tier == 7 || tier == 8) {
        return YES;
    }
    return %orig;
}

- (BOOL)isXPaymentsEnrolled {
    return YES;
}

- (BOOL)isEditProfileUsernameEnabled {
    return YES;
}

- (BOOL)isSensitiveTweetWarningsComposeEnabled {
    return [BHTSettings boolForKey:@"disable_sensitive_tweet_warnings"] ? NO : %orig;
}

- (BOOL)isSensitiveTweetWarningsConsumeEnabled {
    return [BHTSettings boolForKey:@"disable_sensitive_tweet_warnings"] ? NO : %orig;
}

- (BOOL)isAgeAssuranceAgeVerificationFlowEnabled {
    return [BHTSettings boolForKey:@"bypass_age_verification"] ? NO : %orig;
}

- (BOOL)isVideoDynamicAdEnabled {
    return [BHTSettings boolForKey:@"hide_promoted"] ? NO : %orig;
}

- (BOOL)isDoubleMaxZoomFor4KImagesEnabled {
    return [BHTSettings boolForKey:@"auto_highest_load"] ? YES : %orig;
}

%end

// MARK: Sensitive media warnings

%hook TFNTwitterStatus

- (BOOL)hasImageInterstitial {
    return [BHTSettings boolForKey:@"disable_sensitive_tweet_warnings"] ? NO : %orig;
}

- (id)imageInterstitial {
    return [BHTSettings boolForKey:@"disable_sensitive_tweet_warnings"] ? nil : %orig;
}

- (id)innerImageInterstitial {
    return [BHTSettings boolForKey:@"disable_sensitive_tweet_warnings"] ? nil : %orig;
}

%end

%hook HFHealthSafetyFeature

+ (BOOL)isTweetMedialInterstitialEnabled:(id)featureSwitches {
    return [BHTSettings boolForKey:@"disable_sensitive_tweet_warnings"] ? NO : %orig;
}

%end
