//
//  Theme.x
//  NeoFreeBird
//

#import "HookHelpers.h"

// MARK: - Custom accent color

static NSNumber* selectedThemeColor(void) {
    return [NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"];
}

// Every apply path (launch re-apply, trait changes, both settings pickers)
// funnels through this setter, so coercing here keeps the custom color pinned.
%hook TAEColorSettings

- (void)setPrimaryColorOption:(NSInteger)colorOption {
    NSNumber* selectedColor = selectedThemeColor();
    %orig(selectedColor ? selectedColor.integerValue : colorOption);
}

- (NSInteger)primaryColorOption {
    NSNumber* selectedColor = selectedThemeColor();
    return selectedColor ? selectedColor.integerValue : %orig;
}

%end

void applySelectedThemeColor(void) {
    NSNumber* selectedColor = selectedThemeColor();
    if (selectedColor) {
        [[objc_getClass("TAEColorSettings") sharedSettings]
            setPrimaryColorOption:selectedColor.integerValue];
    }
}

// MARK: - Dim background recolor

// The app only ever renders Light or Dark now -- there's no native third
// option -- so Dim comes back by intercepting Dark's palette at its one
// choke point and swapping in a proxy that recolors just the background
// family, leaving Light untouched.
%hook TAETwitterColorPaletteSettingInfo

- (id<TAEColorPalette>)colorPalette {
    id<TAEColorPalette> realPalette = %orig;
    if (self.isDark && BHTDimThemeEnabled()) {
        return (id<TAEColorPalette>)[BHTDimPaletteProxy proxyWithPalette:realPalette];
    }
    return realPalette;
}

%end

// Headers, small containers, profile pages, and the boxes around some cells
// don't go through TAEColorPalette at all -- they're drawn with UIKit's own
// dynamic system background colors, which Apple defines as pure black (or
// near enough) in Dark. Re-point those at the same three Dim shades so
// nothing native-styled is left behind.
%hook UIColor

+ (UIColor*)systemBackgroundColor {
    UIColor* original = %orig;
    if (!BHTDimThemeEnabled()) {
        return original;
    }
    return [UIColor colorWithDynamicProvider:^UIColor*(UITraitCollection* traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? BHTDimBackgroundColor()
                                                                       : original;
    }];
}

+ (UIColor*)secondarySystemBackgroundColor {
    UIColor* original = %orig;
    if (!BHTDimThemeEnabled()) {
        return original;
    }
    return [UIColor colorWithDynamicProvider:^UIColor*(UITraitCollection* traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? BHTDimElevatedBackgroundColor()
                                                                       : original;
    }];
}

+ (UIColor*)tertiarySystemBackgroundColor {
    UIColor* original = %orig;
    if (!BHTDimThemeEnabled()) {
        return original;
    }
    return [UIColor colorWithDynamicProvider:^UIColor*(UITraitCollection* traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? BHTDimHighlightBackgroundColor()
                                                                       : original;
    }];
}

+ (UIColor*)systemGroupedBackgroundColor {
    UIColor* original = %orig;
    if (!BHTDimThemeEnabled()) {
        return original;
    }
    return [UIColor colorWithDynamicProvider:^UIColor*(UITraitCollection* traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? BHTDimBackgroundColor()
                                                                       : original;
    }];
}

+ (UIColor*)secondarySystemGroupedBackgroundColor {
    UIColor* original = %orig;
    if (!BHTDimThemeEnabled()) {
        return original;
    }
    return [UIColor colorWithDynamicProvider:^UIColor*(UITraitCollection* traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? BHTDimElevatedBackgroundColor()
                                                                       : original;
    }];
}

+ (UIColor*)tertiarySystemGroupedBackgroundColor {
    UIColor* original = %orig;
    if (!BHTDimThemeEnabled()) {
        return original;
    }
    return [UIColor colorWithDynamicProvider:^UIColor*(UITraitCollection* traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? BHTDimHighlightBackgroundColor()
                                                                       : original;
    }];
}

%end

// The six named colors above only cover code that calls those exact class
// methods. Plenty of chrome (profile headers, small containers, boxes around
// cells) instead gets its color from a UIDynamicSystemColor (system colors)
// or UIDynamicCatalogColor (colors loaded from an asset catalog, including
// Twitter's own named design-system colors, which we have no way to
// enumerate) stored directly on a view's backgroundColor. Both are UIColor
// subclasses that funnel through -resolvedColorWithTraitCollection: at draw
// time -- hooking there catches every source at once, not just the ones we
// know the name of.
@interface UIDynamicSystemColor : UIColor
@end
@interface UIDynamicCatalogColor : UIColor
@end
// UIExtendedSRGBColorSpace is the concrete storage class behind essentially
// every flat (non-dynamic) UIColor, not just background colors -- so unlike
// the two hooks above, this one leans hard on BHTDimReplacementForResolvedColor's
// filtering (opaque, achromatic, near-black only) to avoid ever touching flat
// black text, icon tints, shadows, or borders that happen to share the class.
@interface UIExtendedSRGBColorSpace : UIColor
@end

@interface UIDeviceRGBColor: UIColor
@end

%hook UIDynamicSystemColor

- (UIColor*)resolvedColorWithTraitCollection:(UITraitCollection*)traitCollection {
    UIColor* original = %orig;
    if (BHTColorIsDimExempt(self)) {
        return original;
    }
    if (!BHTDimThemeEnabled() || traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) {
        return original;
    }
    UIColor* replacement = BHTDimReplacementForResolvedColor(original);
    return replacement ?: original;
}

%end

%hook UIDeviceRGBColor
- (UIColor*)resolvedColorWithTraitCollection:(UITraitCollection*)traitCollection {
    UIColor* original = %orig;
    if (BHTColorIsDimExempt(self)) {
        return original;
    }
    if (!BHTDimThemeEnabled() || traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) {
        return original;
    }
    UIColor* replacement = BHTDimReplacementForResolvedColor(original);
    return replacement ?: original;
}

%end

%hook UIDynamicCatalogColor

- (UIColor*)resolvedColorWithTraitCollection:(UITraitCollection*)traitCollection {
    UIColor* original = %orig;
    if (BHTColorIsDimExempt(self)) {
        return original;
    }
    if (!BHTDimThemeEnabled() || traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) {
        return original;
    }
    UIColor* replacement = BHTDimReplacementForResolvedColor(original);
    return replacement ?: original;
}

%end

%hook UIExtendedSRGBColorSpace

- (UIColor*)resolvedColorWithTraitCollection:(UITraitCollection*)traitCollection {
    UIColor* original = %orig;
    if (BHTColorIsDimExempt(self)) {
        return original;
    }
    if (!BHTDimThemeEnabled() || traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) {
        return original;
    }
    UIColor* replacement = BHTDimReplacementForResolvedColor(original);
    return replacement ?: original;
}

%end

%hook TFNSolidColorView

-(void) didMoveToWindow {
    %orig;
    if (BHTDimThemeEnabled()) {
        self.hidden = TRUE;
    }
}

%end

// TFNButton blends into Dim's navy too well, so its background should stay
// whatever Twitter itself set it to. Skipping our own explicit recolor in
// the UIView hook below isn't enough on its own: that color is still an
// instance of one of the four classes hooked above, which will substitute it
// regardless of which view holds it. Marking the exact color instance here,
// at the moment it's assigned, is what actually keeps the four hooks above
// from touching it.
%hook TFNButton

- (void)setBackgroundColor:(UIColor*)color {
    if (BHTColorIsCloseToWhite(color)) {
        BHTMarkColorDimExempt(color);
    }
    %orig(color);
}

%end

%hook UIView
-(void) didMoveToWindow {
    %orig;
    if ([self isKindOfClass:objc_getClass("TFNButton")] || [self isKindOfClass:objc_getClass("UIImageView")]) {
        return;
    }
    if ([self superview] && [self.superview isKindOfClass:objc_getClass("TFNSolidColorView")]) {
        if (BHTDimThemeEnabled()) {
            // This override is unconditional and bypasses the resolvedColor
            // heuristic entirely, so white chrome needs its own explicit
            // guard here -- forcing it to Dim navy would wreck readability.
            if (BHTColorIsCloseToWhite(self.backgroundColor)) {
                return;
            }
            self.backgroundColor = BHTDimBackgroundColor();
        }
    }
}

%end

// MARK: - Custom tab bar order and visibility

static NSString* scribePageForEntry(id<T1AppNavigationTabEntry> entry) {
    if (![entry respondsToSelector:@selector(tabView)]) {
        return nil;
    }
    return [entry tabView].scribePage;
}

// Operates on the tab ENTRIES, not the button views: the app derives both the
// buttons and their content view controllers from this one array.
static NSArray* orderedTabEntries(NSArray* entries) {
    // Record the underlying tab views so the editor can show real titles and icons.
    NSMutableArray* tabViews = [NSMutableArray new];
    for (id<T1AppNavigationTabEntry> entry in entries) {
        T1TabView* tabView = [entry respondsToSelector:@selector(tabView)] ? [entry tabView] : nil;
        if (tabView) {
            [tabViews addObject:tabView];
        }
    }
    [CustomTabBarUtility recordTabViews:tabViews];

    NSArray<NSString*>* visibleOrder = [CustomTabBarUtility visiblePageIDsInOrder];

    NSMutableDictionary<NSString*, id>* entriesByPage = [NSMutableDictionary new];
    for (id<T1AppNavigationTabEntry> entry in entries) {
        NSString* page = scribePageForEntry(entry);
        if (page && !entriesByPage[page]) {
            entriesByPage[page] = entry;
        }
    }

    // Not customised yet: show the default set (Home, Search, Notifications, Chats)
    // in that order, hiding everything else the app builds.
    if (!visibleOrder) {
        NSMutableArray* defaultEntries = [NSMutableArray new];
        for (NSString* pageID in [CustomTabBarUtility defaultVisiblePageIDs]) {
            id entry = entriesByPage[pageID];
            if (entry) {
                [defaultEntries addObject:entry];
            }
        }
        return defaultEntries;
    }

    // Only the chosen tabs show; anything the editor hasn't been told to show
    // (including tabs unlocked after the user last saved) stays hidden.
    NSMutableArray* orderedEntries = [NSMutableArray new];
    NSMutableSet* placed = [NSMutableSet new];
    for (NSString* pageID in visibleOrder) {
        id entry = entriesByPage[pageID];
        if (entry && ![placed containsObject:pageID]) {
            [orderedEntries addObject:entry];
            [placed addObject:pageID];
        }
    }

    return orderedEntries;
}

// The single ordered spine that feeds both the tab buttons and their content, so
// filtering/reordering here keeps taps mapped to the right panel.
%hook T1TabbedAppNavigationViewController

- (void)setVisibleTabEntries:(NSArray*)entries {
    %orig(orderedTabEntries(entries));
}

%end

// MARK: - Keep tab bar visible

%hook T1TabBarViewController

// The scroll-driven hide only reaches the tab bar as a collapse ratio, so
// clamping it spares the deliberate hides (fullscreen media, immersive player).
- (void)setTabBarCollapseRatio:(double)ratio {
    if ([BHTSettings boolForKey:@"no_tab_bar_hiding"]) {
        %orig(0.0);
    } else {
        %orig(ratio);
    }
}

%end

// MARK: - Tab bar icon and label theming

static BOOL updatingTabIconColor = NO;

static UIColor* tabItemColor(BOOL selected) {
    return selected ? CurrentAccentColor() : [UIColor secondaryLabelColor];
}

%hook T1TabView

- (void)_t1_updateImageViewAnimated:(BOOL)animated {
    // setIconColor: re-enters this method, so swallow the inner call and let
    // %orig below render once with the new color
    if (updatingTabIconColor) {
        return;
    }

    updatingTabIconColor = YES;
    if ([BHTSettings boolForKey:@"tab_bar_theming"]) {
        self.iconColor = tabItemColor(self.selected);
    } else if (self.iconColor) {
        self.iconColor = nil;
    }
    updatingTabIconColor = NO;

    %orig(animated);
}

- (void)_t1_updateTitleLabel {
    %orig;

    if ([BHTSettings boolForKey:@"tab_bar_theming"]) {
        self.titleLabel.textColor = tabItemColor(self.selected);
    }
}

- (BOOL)showsTitleInDisplayMode:(long long)displayMode {
    if ([BHTSettings boolForKey:@"restore_tab_labels"]) {
        return YES;
    }
    return %orig;
}

%new
- (void)applyCurrentThemeToIcon {
    [self _t1_updateImageViewAnimated:NO];
    [self _t1_updateTitleLabel];
}

%end

// MARK: - Top bar logo theming

%hook _TtC11TwitterHome39HomeDefaultNavigationBarTitleViewPlugin

- (UIView*)titleView {
    UIView* titleView = %orig;

    if ([BHTSettings boolForKey:@"color_twitter_icon_in_top_bar"] &&
        [titleView isKindOfClass:[UIImageView class]]) {
        UIImageView* logoView = (UIImageView*)titleView;
        if (logoView.image) {
            logoView.image = [logoView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            logoView.tintColor = CurrentAccentColor();
        }
    }

    return titleView;
}

%end
