//
//  FeatureSwitches.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// While set, -isSubscribedTo: (below) reports the account's genuine subscription
// state instead of the forced premium tiers, so paths that need the real status
// can read through the unlock.
static __thread BOOL BHTReportGenuineSubscription = NO;

// Whether the active account is really a premium subscriber, ignoring the forced
// unlock. Lets switch-gated surfaces that have no premium-aware seam of their own
// follow the genuine status instead of the spoof.
static BOOL BHTAccountIsGenuinelyPremium(void) {
    Class hostClass = objc_getClass("T1HostViewController");
    id host = ((id (*)(id, SEL))objc_msgSend)((id)hostClass, @selector(sharedHostViewController));
    id account = ((id (*)(id, SEL))objc_msgSend)(host, @selector(currentAccount));
    if (![account respondsToSelector:@selector(isPremiumTierUser)]) {
        return NO;
    }

    BOOL saved = BHTReportGenuineSubscription;
    BHTReportGenuineSubscription = YES;
    BOOL premium = ((BOOL (*)(id, SEL))objc_msgSend)(account, @selector(isPremiumTierUser));
    BHTReportGenuineSubscription = saved;
    return premium;
}

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
        [key isEqualToString:@"grok_edit_with_grok_button_under_post_preview_enabled"]) {
        return @YES;
    }

    // Grok analyze: the tweet-side show decisions (timeline author view and post
    // detail nav bar, including its context-menu variant) all gate on the
    // backend-controlled switch before consulting the per-tweet flag.
    if ([key isEqualToString:@"grok_ios_author_view_analyze_button_via_backend_enabled"]) {
        return [BHTSettings boolForKey:@"hide_grok_analyze"] ? @NO : nil;
    }

    // The profile header's analyze (summary) button bottoms out in this switch on
    // both header variants, one of which reads it through a direct Swift call.
    if ([key isEqualToString:@"grok_ios_profile_summary_enabled"]) {
        return @(![BHTSettings boolForKey:@"hide_grok_analyze"]);
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

    // Premium / verification upsells and purchase prompts. The forced tier already
    // self-hides the ones gated on !isPremiumTierUser, but the rest read their own
    // switch regardless, so every upsell surface present in 12.3 is disabled here.
    if ([key isEqualToString:@"ios_profile_analytics_upsell_enabled"] ||
        [key isEqualToString:@"ios_profile_analytics_upsell_possible_enabled"] ||
        [key isEqualToString:@"ios_profile_upgrade_upsell_enabled"] ||
        [key isEqualToString:@"ios_profile_upgrade_upsell_swapper_enabled"] ||
        [key isEqualToString:@"ios_profile_visitor_upsell_enabled"] ||
        [key isEqualToString:@"subscriptions_upsells_get_verified_profile"] ||
        [key isEqualToString:@"subscriptions_upsells_reply_boost_enabled"] ||
        [key isEqualToString:@"subscriptions_upsells_reply_boost_popup_enabled"] ||
        [key isEqualToString:@"subscriptions_upsells_post_analytics_enabled"] ||
        [key isEqualToString:@"subscriptions_upsells_creator_support_post_conversation_enabled"] ||
        [key isEqualToString:@"longform_notetweets_composer_upsell_enabled"] ||
        [key isEqualToString:@"longform_notetweets_composer_auto_upsell_enabled"] ||
        [key isEqualToString:@"subscriptions_cta_on_replies_enabled"] ||
        [key isEqualToString:@"super_follow_upsell_sticky_button_enabled"] ||
        [key isEqualToString:@"subscriptions_new_paywall_enabled"] ||
        [key isEqualToString:@"subscriptions_offers_promotional_enabled"] ||
        [key isEqualToString:@"subscriptions_gifting_premium_enabled"] ||
        [key isEqualToString:@"subscriptions_gifting_premium_intro_copy_enabled"] ||
        [key isEqualToString:@"subscriptions_ios_download_to_offline_upsell_enabled"] ||
        [key isEqualToString:@"ios_notifications_blue_verified_introductory_offer_visible"] ||
        [key isEqualToString:@"ios_notifications_blue_verified_introductory_offer_prefix_visible"] ||
        [key isEqualToString:@"dash_items_download_grok_enabled"]) {
        return @NO;
    }

    // The Premium settings row is gated at its root instead (see the
    // -isSubscriptionsSettingsItemEnabledWithProvider: hook), so it follows the
    // genuine subscription state. The creator purchases dashboard and the
    // subscriber-only profile tab are left untouched: the app already gates those
    // on real creator eligibility, which the forced tier never affects.

    // Creator Studio / Monetization sidebar item (and the Monetization settings
    // row). Its builder gates purely on these switches with no premium check, so the
    // forced tier can't reach it - follow the genuine status here. Monetization
    // requires a real subscription anyway, so a genuine subscriber keeps it while
    // the spoof hides it.
    if ([key isEqualToString:@"creator_studio_nav_enabled"] ||
        [key isEqualToString:@"creator_monetization_dashboard_enabled"]) {
        if (!BHTAccountIsGenuinelyPremium()) {
            return @NO;
        }
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

// Root of the Premium row in Settings, which opens the subscribe paywall. Its own
// gate is subscriptions_enabled || (gating_bypass && isPremiumTierUser), and
// subscriptions_enabled is on for everyone so non-subscribers get the row as an
// upsell - passing genuine status through %orig wouldn't hide it. Short-circuit to
// NO for a genuinely non-premium account (provider is the account), keeping the row
// only for a real subscriber to manage their subscription.
- (BOOL)isSubscriptionsSettingsItemEnabledWithProvider:(id)provider {
    if (![provider respondsToSelector:@selector(isPremiumTierUser)]) {
        return %orig;
    }

    BOOL saved = BHTReportGenuineSubscription;
    BHTReportGenuineSubscription = YES;
    BOOL genuinePremium = ((BOOL (*)(id, SEL))objc_msgSend)(provider, @selector(isPremiumTierUser));
    BHTReportGenuineSubscription = saved;

    if (!genuinePremium) {
        return NO;
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

// Premium tier state funnels through -isSubscribedTo:, which reads the account's
// subscription claims: isPremiumTierUser checks tiers 0/7/8, isVerifiedPremiumTierUser
// checks 0/8, and isSubscribedToAnyPremiumTier builds on those. Forcing the premium
// tiers here unlocks premium across every account-level check from one stable seam.
- (BOOL)isSubscribedTo:(NSUInteger)tier {
    if (!BHTReportGenuineSubscription && (tier == 0 || tier == 7 || tier == 8)) {
        return YES;
    }
    return %orig;
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

// MARK: Genuine subscription status for outward-facing paths

// The forced tier unlocks features, but a few paths report subscription status
// outward (to marketing) or expose the real subscription management. Running them
// against the genuine status means a real subscriber is handled normally while a
// forced unlock is never announced as premium.

%hook T1AppServicesManager

// Sets the account's tier as a Braze attribute on every activation.
- (id)_brazeTierStringForAccount:(id)account {
    BOOL saved = BHTReportGenuineSubscription;
    BHTReportGenuineSubscription = YES;
    id result = %orig;
    BHTReportGenuineSubscription = saved;
    return result;
}

%end

%hook T1TabbedAppNavigation

// Opens the real subscription management flow and fetches preferences from the
// server; its own premium check should see the genuine status, so a forced unlock
// stops here while a real subscriber keeps access.
- (void)showPremiumHubManageSubscriptionWithSource:(NSInteger)source withCompletion:(id)completion {
    BOOL saved = BHTReportGenuineSubscription;
    BHTReportGenuineSubscription = YES;
    %orig;
    BHTReportGenuineSubscription = saved;
}

%end

%hook T1ProfileSummaryView

// The profile "under review" verification prompt shows when the account is a
// verified-premium tier user that isn't blue-verified yet - a state the forced tier
// fabricates for a non-subscriber. Reading it against the genuine status hides the
// prompt for a non-premium account while leaving it for a real subscriber awaiting
// verification.
- (BOOL)shouldShowUnderReviewButton {
    BOOL saved = BHTReportGenuineSubscription;
    BHTReportGenuineSubscription = YES;
    BOOL result = %orig;
    BHTReportGenuineSubscription = saved;
    return result;
}

%end

// MARK: Premium side-drawer row

// The account side drawer is a SwiftUI List with no data or model seam - the items
// are assembled in Swift and handed straight to SwiftUI, and every row is a shared
// SwiftUI.ListCollectionViewCell. The only reachable layer is the UICollectionView
// underneath, and SwiftUI does not expose the row text to us, so match the Premium
// row by its position (always the second entry) within the drawer's collection view.
// Scoped to the drawer's host controller so it can't affect other SwiftUI lists, and
// keyed on index rather than text so it stays locale-independent. Re-evaluated each
// pass so recycled cells are restored.

static BOOL BHTIsPremiumDrawerCell(UIView *cell) {
    if (![cell isKindOfClass:[UICollectionViewCell class]]) {
        return NO;
    }

    Class dashClass = NSClassFromString(@"TwitterDash.DashHostingController");
    if (!dashClass) {
        return NO;
    }

    BOOL inDrawer = NO;
    for (UIResponder *responder = cell; responder != nil; responder = responder.nextResponder) {
        if ([responder isKindOfClass:dashClass]) {
            inDrawer = YES;
            break;
        }
    }
    if (!inDrawer) {
        return NO;
    }

    UIView *view = cell.superview;
    while (view && ![view isKindOfClass:[UICollectionView class]]) {
        view = view.superview;
    }
    UICollectionView *collectionView = (UICollectionView *)view;
    if (!collectionView) {
        return NO;
    }

    NSIndexPath *indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
    return indexPath && indexPath.section == 0 && indexPath.item == 1;
}

static void (*BHTOrigListCellLayoutSubviews)(UIView *, SEL);

static void BHTListCellLayoutSubviews(UIView *self, SEL _cmd) {
    BHTOrigListCellLayoutSubviews(self, _cmd);

    BOOL shouldHide = BHTIsPremiumDrawerCell(self) && !BHTAccountIsGenuinelyPremium();
    if (self.hidden != shouldHide) {
        self.hidden = shouldHide;
    }
}

static id (*BHTOrigListCellPreferredAttrs)(UIView *, SEL, id);

static id BHTListCellPreferredAttrs(UIView *self, SEL _cmd, id attributes) {
    id result = BHTOrigListCellPreferredAttrs(self, _cmd, attributes);

    if ([result isKindOfClass:[UICollectionViewLayoutAttributes class]] &&
        BHTIsPremiumDrawerCell(self) && !BHTAccountIsGenuinelyPremium()) {
        UICollectionViewLayoutAttributes *attrs = result;
        CGRect frame = attrs.frame;
        frame.size.height = 0;
        attrs.frame = frame;
    }
    return result;
}

%ctor {
    Class listCell = NSClassFromString(@"SwiftUI.ListCollectionViewCell");
    if (listCell) {
        Method layout = class_getInstanceMethod(listCell, @selector(layoutSubviews));
        if (layout) {
            BHTOrigListCellLayoutSubviews = (void (*)(UIView *, SEL))method_getImplementation(layout);
            method_setImplementation(layout, (IMP)BHTListCellLayoutSubviews);
        }

        Method preferred = class_getInstanceMethod(listCell, @selector(preferredLayoutAttributesFittingAttributes:));
        if (preferred) {
            BHTOrigListCellPreferredAttrs = (id (*)(UIView *, SEL, id))method_getImplementation(preferred);
            method_setImplementation(preferred, (IMP)BHTListCellPreferredAttrs);
        }
    }
}

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
