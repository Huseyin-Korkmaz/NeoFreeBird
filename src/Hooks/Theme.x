//
//  Theme.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: - Custom accent color

static NSNumber *BHT_selectedThemeColor(void) {
    return [NSUserDefaults.standardUserDefaults objectForKey:@"bh_color_theme_selectedColor"];
}

// Every apply path (Twitter's launch re-apply, trait changes and both the
// legacy and Swift settings pickers) funnels through this setter, so coercing
// the option here is enough to keep the custom color pinned.
%hook TAEColorSettings

- (void)setPrimaryColorOption:(NSInteger)colorOption {
    NSNumber *selectedColor = BHT_selectedThemeColor();
    %orig(selectedColor ? selectedColor.integerValue : colorOption);
}

- (NSInteger)primaryColorOption {
    NSNumber *selectedColor = BHT_selectedThemeColor();
    return selectedColor ? selectedColor.integerValue : %orig;
}

%end

void BHT_applySelectedThemeColor(void) {
    NSNumber *selectedColor = BHT_selectedThemeColor();
    if (selectedColor) {
        [[objc_getClass("TAEColorSettings") sharedSettings] setPrimaryColorOption:selectedColor.integerValue];
    }
}

// MARK: - Tab bar visibility

static NSArray *BHT_filteredTabViews(NSArray *tabViews) {
    NSArray <NSString *> *hiddenBars = [BHCustomTabBarUtility getHiddenTabBars];
    BOOL hideGrokByDefault = ![NSUserDefaults.standardUserDefaults boolForKey:@"ios_tab_bar_default_show_grok"];

    NSMutableArray *visibleTabViews = [NSMutableArray new];
    for (T1TabView *tabView in tabViews) {
        if ([hiddenBars containsObject:tabView.scribePage]) {
            continue;
        }
        if (hideGrokByDefault && [tabView.scribePage isEqualToString:@"grok"]) {
            continue;
        }
        [visibleTabViews addObject:tabView];
    }

    return visibleTabViews;
}

%hook T1TabBarViewController

// The scroll-driven hide only ever reaches the tab bar as a collapse ratio,
// so clamping it keeps the bar visible without touching the deliberate hide
// paths (fullscreen media, immersive player)
- (void)setTabBarCollapseRatio:(double)ratio {
    if ([BHTSettings boolForKey:@"no_tab_bar_hiding"]) {
        %orig(0.0);
    } else {
        %orig(ratio);
    }
}

- (void)setTabViews:(NSArray *)tabViews {
    %orig(BHT_filteredTabViews(tabViews));
}

%end

// iOS 26 tab bar
%hook T1LiquidGlassTabBarController

- (void)setTabViews:(NSArray *)tabViews {
    %orig(BHT_filteredTabViews(tabViews));
}

%end

// MARK: - Tab bar icon and label theming

static BOOL BHT_updatingTabIconColor = NO;

static UIColor *BHT_tabItemColor(BOOL selected) {
    return selected ? BHTCurrentAccentColor() : [UIColor secondaryLabelColor];
}

%hook T1TabView

- (void)_t1_updateImageViewAnimated:(BOOL)animated {
    // setIconColor: re-enters this method, so swallow the inner call and let
    // %orig below render once with the new color
    if (BHT_updatingTabIconColor) {
        return;
    }

    BHT_updatingTabIconColor = YES;
    if ([BHTSettings boolForKey:@"tab_bar_theming"]) {
        self.iconColor = BHT_tabItemColor(self.selected);
    } else if (self.iconColor) {
        self.iconColor = nil;
    }
    BHT_updatingTabIconColor = NO;

    %orig(animated);
}

- (void)_t1_updateTitleLabel {
    %orig;

    if ([BHTSettings boolForKey:@"tab_bar_theming"]) {
        self.titleLabel.textColor = BHT_tabItemColor(self.selected);
    }
}

- (BOOL)showsTitleInDisplayMode:(long long)displayMode {
    if ([BHTSettings boolForKey:@"restore_tab_labels"]) {
        return YES;
    }
    return %orig;
}

%new
- (void)bh_applyCurrentThemeToIcon {
    [self _t1_updateImageViewAnimated:NO];
    [self _t1_updateTitleLabel];
}

%end

// MARK: - Top bar logo theming, controlled by "color_twitter_icon_in_top_bar"

%hook _TtC11TwitterHome39HomeDefaultNavigationBarTitleViewPlugin

- (UIView *)titleView {
    UIView *titleView = %orig;

    if ([BHTSettings boolForKey:@"color_twitter_icon_in_top_bar"] && [titleView isKindOfClass:[UIImageView class]]) {
        UIImageView *logoView = (UIImageView *)titleView;
        if (logoView.image) {
            logoView.image = [logoView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            logoView.tintColor = BHTCurrentAccentColor();
        }
    }

    return titleView;
}

%end
