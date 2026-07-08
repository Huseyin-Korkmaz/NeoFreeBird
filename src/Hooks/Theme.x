//
//  Theme.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// Theme state tracking
static BOOL BHT_themeManagerInitialized = NO;
static BOOL BHT_isInThemeChangeOperation = NO;
// Helper function to get Twitter's current dark mode state
static BOOL BHT_isTwitterDarkThemeActive() {
    Class TAEColorSettingsCls = objc_getClass("TAEColorSettings");
    if (!TAEColorSettingsCls) {
        if (@available(iOS 13.0, *)) {
            return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        }
        return NO; // Default to light mode if essential classes are missing
    }

    id settings = [TAEColorSettingsCls sharedSettings];
    if (!settings || ![settings respondsToSelector:@selector(currentColorPalette)]) {
        if (@available(iOS 13.0, *)) {
            return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        }
        return NO;
    }

    id currentPaletteContainer = [settings currentColorPalette]; // This is TAEThemeColorPalette
    // TAETwitterColorPaletteSettingInfo is returned by [TAEThemeColorPalette colorPalette]
    if (!currentPaletteContainer || ![currentPaletteContainer respondsToSelector:@selector(colorPalette)]) {
         if (@available(iOS 13.0, *)) {
            return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        }
        return NO;
    }

    id actualPaletteInfo = [currentPaletteContainer colorPalette];
    if (actualPaletteInfo && [actualPaletteInfo respondsToSelector:@selector(isDark)]) {
        // Use objc_msgSend to call the isDark method
        return ((BOOL (*)(id, SEL))objc_msgSend)(actualPaletteInfo, @selector(isDark));
    }

    // Fallback to system trait if Twitter's internal state is inaccessible
    if (@available(iOS 13.0, *)) {
        return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return NO;
}

// MARK: - Core TAE Color hooks
%hook TAEColorSettings

- (instancetype)init {
    id instance = %orig;
    if (instance && !BHT_themeManagerInitialized) {
        // Register for system theme and appearance related notifications
        [[NSNotificationCenter defaultCenter] addObserverForName:@"UITraitCollectionDidChangeNotification"
                                                         object:nil
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification * _Nonnull note) {
            if ([NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BHT_ensureThemingEngineSynchronized(NO);
                });
            }
        }];

        // Also listen for app entering foreground
        [[NSNotificationCenter defaultCenter] addObserverForName:@"UIApplicationWillEnterForegroundNotification"
                                                         object:nil
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification * _Nonnull note) {
            if ([NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BHT_ensureThemingEngineSynchronized(YES);
                });
            }
        }];

        BHT_themeManagerInitialized = YES;
    }
    return instance;
}

- (void)setPrimaryColorOption:(NSInteger)colorOption {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // If we have a BHTwitter theme selected, ensure it takes precedence
    if ([defaults objectForKey:@"bh_color_theme_selectedColor"]) {
        NSInteger ourSelectedOption = [defaults integerForKey:@"bh_color_theme_selectedColor"];

        // Only allow changes that match our selection (avoids fighting with Twitter's system)
        if (colorOption == ourSelectedOption || BHT_isInThemeChangeOperation) {
            %orig(colorOption);
        } else {
            // If not from our theme operation, apply our own theme instead
            %orig(ourSelectedOption);

            // Also ensure Twitter's defaults match our setting for consistency
            [defaults setObject:@(ourSelectedOption) forKey:@"T1ColorSettingsPrimaryColorOptionKey"];
        }
    } else {
        // No BHTwitter theme active, let Twitter handle it normally
        %orig(colorOption);
    }
}

- (void)applyCurrentColorPalette {
    %orig;

    // Signal UI to refresh after Twitter applies its palette
    if ([NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"] &&
        !BHT_isInThemeChangeOperation &&
        [BHTManager classicTabBarEnabled]) {
        // This call happens after Twitter has applied its color changes,
        // so we need to refresh our tab bar theming
        dispatch_async(dispatch_get_main_queue(), ^{
            BHT_UpdateAllTabBarIcons();
        });
    }
}

%end

%hook T1ColorSettings

+ (void)_t1_applyPrimaryColorOption {
    // Execute original implementation to let Twitter update its internal state
    %orig;

    // If we have an active theme, ensure it's properly applied
    if ([NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"]) {
        // Synchronize our theme if needed (without forcing)
        BHT_ensureThemingEngineSynchronized(NO);
    }
}

+ (void)_t1_updateOverrideUserInterfaceStyle {
    // Let Twitter update its UI style
    %orig;

    // Ensure our theme isn't lost during dark/light mode changes
    if ([NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"] &&
        [BHTManager classicTabBarEnabled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BHT_UpdateAllTabBarIcons();
        });
    }
}

%end

%hook NSUserDefaults

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    // Protect our custom theme from being overwritten by Twitter
    if ([defaultName isEqualToString:@"T1ColorSettingsPrimaryColorOptionKey"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        id selectedColor = [defaults objectForKey:@"bh_color_theme_selectedColor"];

        if (selectedColor != nil && !BHT_isInThemeChangeOperation) {
            // If our theme is active and this change isn't part of our operation,
            // only allow the change if it matches our selection
            if (![value isEqual:selectedColor]) {
                // Silently reject the change, our theme has priority
                return;
            }
        }
    }

    %orig;
}

%end
// MARK: prevent tab bar fade
%hook T1TabBarViewController

- (void)setTabBarScrolling:(BOOL)scrolling {
    if ([BHTManager stopHidingTabBar]) {
        %orig(NO); // Force scrolling to NO if fading is prevented
    } else {
        %orig(scrolling);
    }
}

- (void)loadView {
    %orig;
    NSArray <NSString *> *hiddenBars = [BHCustomTabBarUtility getHiddenTabBars];
    BOOL hideGrokByDefault = ![[NSUserDefaults standardUserDefaults] boolForKey:@"ios_tab_bar_default_show_grok"];
    for (T1TabView *tabView in self.tabViews) {
        if ([hiddenBars containsObject:tabView.scribePage] ||
            (hideGrokByDefault && [tabView.scribePage isEqualToString:@"grok"])) {
            [tabView setHidden:true];
        }
    }
}
%end
// Helper for the Twitter icon theming setting
static BOOL BHColorTwitterIconEnabled(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"color_twitter_icon_in_top_bar"] == nil) {
        return [BHTManager isTwitterBranded];
    }

    return [defaults boolForKey:@"color_twitter_icon_in_top_bar"];
}

// MARK: Bird Icon Theming, controlled by "color_twitter_icon_in_top_bar"

%hook UIImageView

- (void)setImage:(UIImage *)image {
    // If the setting is off, keep the original behavior
    if (!BHColorTwitterIconEnabled()) {
        %orig(image);
        return;
    }

    %orig(image);

    if (!image) return;

    // Check if this is the Twitter bird icon by examining the image's dynamic color name
    if ([image respondsToSelector:@selector(tfn_dynamicColorImageName)]) {
        NSString *imageName = [image performSelector:@selector(tfn_dynamicColorImageName)];
        if ([imageName isEqualToString:@"twitter"]) {
            if (image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
                UIImage *templateImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.image = templateImage;
                self.tintColor = BHTCurrentAccentColor();
            }
        }
    }
}

%end
// MARK: - Classic Tab Bar Icon Theming
%hook T1TabView

%new
- (void)bh_applyCurrentThemeToIcon {
    UIImageView *imageView = [self valueForKey:@"imageView"];
    UILabel *titleLabel = [self valueForKey:@"titleLabel"];
    if (!imageView) return;

    BOOL isSelected = [[self valueForKey:@"selected"] boolValue];

    if ([BHTManager classicTabBarEnabled]) {
        // Apply custom theming
        UIColor *targetColor = isSelected ? BHTCurrentAccentColor() : [UIColor secondaryLabelColor];

        // Ensure image is in template mode for proper tinting
        if (imageView.image && imageView.image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
            imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }

        // Apply tint color to icon
        imageView.tintColor = targetColor;

        // Apply color to label
        if (titleLabel) {
            titleLabel.textColor = targetColor;
        }
    } else {
        // Revert to default Twitter appearance
        imageView.tintColor = nil;

        // Reset image rendering mode to automatic
        if (imageView.image) {
            imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAutomatic];
        }

        // Reset label color to default
        if (titleLabel) {
            titleLabel.textColor = nil;
        }
    }
}

- (BOOL)_t1_showsTitle {
    if ([BHTManager restoreTabLabels]) {
        return true;
    }
    return %orig;
}

- (void)_t1_updateTitleLabel {
    %orig;

    // Ensure titleLabel is not hidden when restore tab labels is enabled
    if ([BHTManager restoreTabLabels]) {
        UILabel *titleLabel = [self valueForKey:@"titleLabel"];
        if (titleLabel) {
            titleLabel.hidden = NO;
        }
    }
}

- (void)_t1_updateImageViewAnimated:(_Bool)animated {
    %orig(animated);

    // Always apply theming logic (handles both enabled and disabled cases)
    [self performSelector:@selector(bh_applyCurrentThemeToIcon)];
}

- (void)setSelected:(_Bool)selected {
    %orig(selected);

    // Always apply theming logic (handles both enabled and disabled cases)
    [self performSelector:@selector(bh_applyCurrentThemeToIcon)];
}

%end



// MARK: - Tab Bar Controller Theme Integration
%hook T1TabBarViewController

- (void)_t1_updateTabBarAppearance {
    %orig;

    // Apply our custom theming after Twitter updates the tab bar
    if ([BHTManager classicTabBarEnabled]) {
        NSArray *tabViews = [self valueForKey:@"tabViews"];
        for (id tabView in tabViews) {
            if ([tabView respondsToSelector:@selector(bh_applyCurrentThemeToIcon)]) {
                [tabView performSelector:@selector(bh_applyCurrentThemeToIcon)];
            }
        }
    }
}

%end

// Helper: Update all tab bar icons using Twitter's internal methods
void BHT_UpdateAllTabBarIcons(void) {
    // Use Twitter's notification system to refresh tab bars
    [[NSNotificationCenter defaultCenter] postNotificationName:@"T1TabBarAppearanceDidChangeNotification" object:nil];

    // Also trigger a direct refresh on visible tab bar controllers
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow && window.rootViewController) {
            UIViewController *rootVC = window.rootViewController;

            if ([rootVC isKindOfClass:NSClassFromString(@"T1TabBarViewController")]) {
                // Use Twitter's internal tab bar refresh method if available
                if ([rootVC respondsToSelector:@selector(_t1_updateTabBarAppearance)]) {
                    [rootVC performSelector:@selector(_t1_updateTabBarAppearance)];
                }
            }
        }
    }
}

void BHT_applyThemeToWindow(UIWindow *window) {
    if (!window || !window.rootViewController) return;

    // Simply trigger Twitter's internal appearance update
    if ([window.rootViewController isKindOfClass:NSClassFromString(@"T1TabBarViewController")]) {
        if ([window.rootViewController respondsToSelector:@selector(_t1_updateTabBarAppearance)]) {
            [window.rootViewController performSelector:@selector(_t1_updateTabBarAppearance)];
        }
    }
}

// Helper to synchronize theme engine and ensure our theme is active
void BHT_ensureThemingEngineSynchronized(BOOL forceSynchronize) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id selectedColorObj = [defaults objectForKey:@"bh_color_theme_selectedColor"];

    if (!selectedColorObj) return;

    NSInteger selectedColor = [selectedColorObj integerValue];
    id twitterColorObj = [defaults objectForKey:@"T1ColorSettingsPrimaryColorOptionKey"];

    // Check if Twitter's color setting matches our desired color
    if (forceSynchronize || !twitterColorObj || ![twitterColorObj isEqual:selectedColorObj]) {
        // Mark that we're performing our own theme change to avoid recursion
        BHT_isInThemeChangeOperation = YES;

        // Apply our theme color through Twitter's system
        TAEColorSettings *taeSettings = [%c(TAEColorSettings) sharedSettings];
        if ([taeSettings respondsToSelector:@selector(setPrimaryColorOption:)]) {
            [taeSettings setPrimaryColorOption:selectedColor];
        }

        // Set Twitter's user defaults key to match our selection
        [defaults setObject:selectedColorObj forKey:@"T1ColorSettingsPrimaryColorOptionKey"];

        // Call Twitter's internal theme application methods
        if ([%c(T1ColorSettings) respondsToSelector:@selector(_t1_applyPrimaryColorOption)]) {
            [%c(T1ColorSettings) _t1_applyPrimaryColorOption];
        }

        // Refresh only tab bar icons when classic theming is enabled
        if ([BHTManager classicTabBarEnabled]) {
            BHT_UpdateAllTabBarIcons();
        }

        // Reset our operation flag
        BHT_isInThemeChangeOperation = NO;
    }
}
// MARK: Theme TFNBarButtonItemButtonV1
%hook TFNBarButtonItemButtonV1

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        // Trigger our setTintColor logic
        self.tintColor = [UIColor blackColor];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    BOOL isDark = BHT_isTwitterDarkThemeActive();
    UIColor *correctColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    %orig(correctColor);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            // Trigger our setTintColor logic
            self.tintColor = [UIColor blackColor];
        }
    }
%end

%ctor {
    %init;

    // Re-apply the selected theme to windows as they become visible
    [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeVisibleNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification * _Nonnull note) {
        UIWindow *window = note.object;
        if (window && [[NSUserDefaults standardUserDefaults] objectForKey:@"bh_color_theme_selectedColor"]) {
            BHT_applyThemeToWindow(window);
        }
    }];
}
