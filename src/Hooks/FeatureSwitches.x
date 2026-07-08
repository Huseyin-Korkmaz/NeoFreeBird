//
//  FeatureSwitches.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static NSString *BHTFeatureSwitchKeyForFeature(id feature) {
    if (!feature || ![feature respondsToSelector:@selector(key)]) {
        return nil;
    }

    NSString *(*keyMessage)(id, SEL) = (NSString *(*)(id, SEL))objc_msgSend;
    NSString *key = keyMessage(feature, @selector(key));
    return [key isKindOfClass:[NSString class]] ? key : nil;
}

static NSNumber *BHTFeatureSwitchOverrideValueForKey(NSString *key) {
    if (![key isKindOfClass:[NSString class]]) {
        return nil;
    }

    // Custom timelines overrides
    BOOL hideCustomTimelines = [BHTManager hideCustomTimelines];
    if ([key isEqualToString:@"hometimeline_pinned_tabs_topics_enabled"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_generic_timelines_enabled"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_sticky_warm_start_enabled"] ||
        [key isEqualToString:@"home_timeline_sticky_pinned_tab_enabled"] ||
        [key isEqualToString:@"super_follow_subscriptions_home_timeline_tab_sticky_enabled"]) {
        return hideCustomTimelines ? @NO : @YES;
    }

    if ([key isEqualToString:@"home_timeline_non_sticky_tab_on_new_session_enabled"]) {
        return @NO;
    }

    if ([key isEqualToString:@"hometimeline_pinned_tabs_limit"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_management_pinnedsection_inline_limit"] ||
        [key isEqualToString:@"hometimeline_pinned_tabs_management_topics_inline_limit"]) {
        return hideCustomTimelines ? @0 : @100;
    }

    // Edit tweet
    if ([key isEqualToString:@"edit_tweet_enabled"] ||
        [key isEqualToString:@"edit_tweet_ga_composition_enabled"] ||
        [key isEqualToString:@"edit_tweet_pdp_dialog_enabled"] ||
        [key isEqualToString:@"edit_tweet_upsell_enabled"]) {
        return @YES;
    }

    // Grok translations
    if ([key isEqualToString:@"grok_translations_bio_inline_translation_is_enabled"] ||
        [key isEqualToString:@"grok_translations_bio_translation_is_enabled"]) {
        return @([BHTManager BioTranslate]);
    }

    if ([key isEqualToString:@"grok_translations_post_inline_translation_is_enabled"] ||
        [key isEqualToString:@"grok_translations_post_translation_is_enabled"]) {
        return @YES;
    }

    // Profile tabs
    if ([key isEqualToString:@"articles_timeline_profile_tab_enabled"]) {
        return @(![BHTManager disableArticles]);
    }

    if ([key isEqualToString:@"highlights_tweets_tab_ui_enabled"]) {
        return @(![BHTManager disableHighlights]);
    }

    if ([key isEqualToString:@"media_tab_profile_videos_tab_enabled"] ||
        [key isEqualToString:@"media_tab_profile_photos_tab_enabled"] ||
        [key isEqualToString:@"media_tab_enabled"] ||
        [key isEqualToString:@"media_tab_profile_videos_tab_new_design_enabled"]) {
        return @(![BHTManager disableMediaTab]);
    }

    // Age verification bypass
    if ([key hasPrefix:@"ios_age_assurance"] || [key isEqualToString:@"grok_settings_age_restriction_enabled"]) {
        if ([BHTManager bypassAgeVerification]) {
            return @NO;
        }
    }

    // Conversation / tweet detail
    if ([key isEqualToString:@"conversational_replies_ios_minimal_detail_enabled"]) {
        return @(![BHTManager OldStyle]);
    }

    if ([key isEqualToString:@"reply_sorting_enabled"]) {
        return @(![BHTManager replySorting]);
    }

    if ([key isEqualToString:@"ios_tweet_detail_overflow_in_navigation_enabled"]) {
        return @NO;
    }

    if ([key isEqualToString:@"ios_tweet_detail_conversation_context_removal_enabled"]) {
        return @(![BHTManager restoreReplyContext]);
    }

    // Tab bar configuration
    if ([key isEqualToString:@"ios_tab_bar_default_show_grok"]) {
        return @([[NSUserDefaults standardUserDefaults] boolForKey:@"ios_tab_bar_default_show_grok"]);
    }

    if ([key isEqualToString:@"ios_tab_bar_default_show_profile"]) {
        return @([[NSUserDefaults standardUserDefaults] boolForKey:@"ios_tab_bar_default_show_profile"]);
    }

    if ([key isEqualToString:@"ios_tab_bar_default_show_communities"]) {
        return @([[NSUserDefaults standardUserDefaults] boolForKey:@"ios_tab_bar_default_show_communities"]);
    }

    // In-app article webview
    if ([key isEqualToString:@"ios_in_app_article_webview_enabled"]) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        if ([d objectForKey:key] != nil) {
            return @([d boolForKey:key]);
        }
        return @YES;
    }

    // Premium / subscription upsell disables
    if ([key isEqualToString:@"creator_purchases_dashboard_enabled"] ||
        [key isEqualToString:@"subscriptions_settings_item_enabled"] ||
        [key isEqualToString:@"grok_ios_profile_summary_enabled"] ||
        [key isEqualToString:@"creator_monetization_dashboard_enabled"] ||
        [key isEqualToString:@"creator_monetization_profile_subscription_tweets_tab_enabled"] ||
        [key isEqualToString:@"ios_subscription_journey_enabled"] ||
        [key isEqualToString:@"subscriptions_upsells_get_verified_profile"] ||
        [key isEqualToString:@"ios_profile_analytics_upsell_possible_enabled"] ||
        [key isEqualToString:@"ios_profile_analytics_upsell_enabled"] ||
        [key isEqualToString:@"subscriptions_verification_info_is_identity_verified"] ||
        [key isEqualToString:@"subscriptions_verification_info_reason_enabled"] ||
        [key isEqualToString:@"subscriptions_verification_info_verified_since_enabled"] ||
        [key isEqualToString:@"communities_enable_explore_tab"] ||
        [key isEqualToString:@"dash_items_download_grok_enabled"]) {
        return @NO;
    }

    return nil;
}

// MARK: Voice, SensitiveTweetWarnings, autoHighestLoad, VideoZoom, VODCaptions, disableSpacesBar feature
%hook TPSTwitterFeatureSwitches
// Twitter save all the features and keys in side JSON file in bundle of application fs_embedded_defaults_production.json, and use it in TFNTwitterAccount class but with DM voice maybe developers forget to add boolean variable in the class, so i had to change it from the file.
// also, you can find every key for every feature i used in this tweak, i can remove all the codes below and find every key for it but I'm lazy to do that, :)
- (BOOL)boolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.boolValue;
    }

    return %orig;
}

- (id)featureSwitchValueForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (NSInteger)integerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.integerValue;
    }

    return %orig;
}

- (NSNumber *)numberForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (id)rawValueForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (BOOL)unsafePeekBoolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.boolValue;
    }

    return %orig;
}

- (NSInteger)unsafePeekIntegerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.integerValue;
    }

    return %orig;
}
%end

%hook TFSAccountFeatureSwitches
- (BOOL)boolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.boolValue;
    }

    return %orig;
}

- (id)featureSwitchValueForFeature:(id)feature {
    NSString *key = BHTFeatureSwitchKeyForFeature(feature);
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (NSNumber *)numberValueForFeature:(id)feature {
    NSString *key = BHTFeatureSwitchKeyForFeature(feature);
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}
%end

%hook TFSFeatureSwitches
- (BOOL)boolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.boolValue;
    }

    return %orig;
}

- (id)featureSwitchValueForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (NSInteger)integerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.integerValue;
    }

    return %orig;
}

- (NSNumber *)numberForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (id)rawValueForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override;
    }

    return %orig;
}

- (BOOL)unsafePeekBoolForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.boolValue;
    }

    return %orig;
}

- (NSInteger)unsafePeekIntegerForKey:(NSString *)key {
    NSNumber *override = BHTFeatureSwitchOverrideValueForKey(key);
    if (override) {
        return override.integerValue;
    }

    return %orig;
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
%hook TFNTwitterMediaUploadConfiguration
- (_Bool)photoUploadHighQualityImagesSettingIsVisible {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
%end

%hook T1SlideshowViewController
- (_Bool)_t1_shouldDisplayLoadHighQualityImageItemForImageDisplayView:(id)arg1 highestQuality:(_Bool)arg2 {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
- (id)_t1_loadHighQualityActionItemWithTitle:(id)arg1 forImageDisplayView:(id)arg2 highestQuality:(_Bool)arg3 {
    if ([BHTManager autoHighestLoad]) {
        arg3 = true;
    }
    return %orig(arg1, arg2, arg3);
}
%end

%hook T1ImageDisplayView
- (_Bool)_tfn_shouldUseHighestQualityImage {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
- (_Bool)_tfn_shouldUseHighQualityImage {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
%end

%hook T1HighQualityImagesUploadSettings
- (_Bool)shouldUploadHighQualityImages {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
%end

%hook TFSTwitterAPICommandAccountStateProvider
- (BOOL)allowPromotedContent {
    return [BHTManager HidePromoted] ? NO : %orig;
}
%end

%hook TFNTwitterAccount
- (BOOL)_isSubscriptionsGatingBypassEnabled {
    return YES;
}

- (BOOL)canAccessXPayments {
    return YES;
}

- (BOOL)isGrokAskGrokButtonUnderPostFocalEnabled {
    return YES;
}

- (BOOL)isGrokAskGrokButtonUnderPostPreviewEnabled {
    return YES;
}

- (BOOL)isGrokEditWithGrokButtonUnderPostFocalEnabled {
    return YES;
}

- (BOOL)isGrokEditWithGrokButtonUnderPostPreviewEnabled {
    return YES;
}

- (BOOL)isPremiumTierUser {
    return YES;
}

- (BOOL)isXPaymentsEnrolled {
    return YES;
}

- (_Bool)isEditProfileUsernameEnabled {
    return true;
}
- (_Bool)isEditTweetConsumptionEnabled {
    return true;
}
- (_Bool)isSensitiveTweetWarningsComposeEnabled {
    return [BHTManager disableSensitiveTweetWarnings] ? false : %orig;
}
- (_Bool)isSensitiveTweetWarningsConsumeEnabled {
    return [BHTManager disableSensitiveTweetWarnings] ? false : %orig;
}
- (BOOL)isAgeAssuranceAgeVerificationFlowEnabled {
    return [BHTManager bypassAgeVerification] ? NO : %orig;
}
- (_Bool)isVideoDynamicAdEnabled {
    return [BHTManager HidePromoted] ? false : %orig;
}

- (_Bool)isVODCaptionsEnabled {
    return [BHTManager DisableVODCaptions] ? false : %orig;
}
- (_Bool)photoUploadHighQualityImagesSettingIsVisible {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
- (_Bool)loadingHighestQualityImageVariantPermitted {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
- (_Bool)isDoubleMaxZoomFor4KImagesEnabled {
    return [BHTManager autoHighestLoad] ? true : %orig;
}
%end

%hook _TtCV4Grok12GrokRootView9ViewModel
- (BOOL)_isPremiumUser {
    return YES;
}
%end

%hook TFNTwitterStatus
- (BOOL)hasImageInterstitial {
    return [BHTManager disableSensitiveTweetWarnings] ? false : %orig;
}

- (id)imageInterstitial {
    return [BHTManager disableSensitiveTweetWarnings] ? nil : %orig;
}

- (id)innerImageInterstitial {
    return [BHTManager disableSensitiveTweetWarnings] ? nil : %orig;
}

- (BOOL)isPossiblySensitiveViewModelForAccount:(id)account {
    return [BHTManager disableSensitiveTweetWarnings] ? false : %orig;
}
%end

%hook HFHealthSafetyFeature
+ (BOOL)isTweetMedialInterstitialEnabled:(id)featureSwitches {
    return [BHTManager disableSensitiveTweetWarnings] ? false : %orig;
}
%end
