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

static NSString *BHT_scribePageForEntry(id<T1AppNavigationTabEntry> entry) {
    if (![entry respondsToSelector:@selector(tabView)]) {
        return nil;
    }
    return [entry tabView].scribePage;
}

// Filtering and ordering happen on the tab ENTRIES (not the button views) because
// the app derives both the tab buttons and their content view controllers from
// this one array. Reordering the buttons alone would leave the content behind and
// desync taps from panels.
static NSArray *BHT_orderedTabEntries(NSArray *entries) {
    // Record the underlying tab views so the editor can show real titles and icons.
    NSMutableArray *tabViews = [NSMutableArray new];
    for (id<T1AppNavigationTabEntry> entry in entries) {
        T1TabView *tabView = [entry respondsToSelector:@selector(tabView)] ? [entry tabView] : nil;
        if (tabView) {
            [tabViews addObject:tabView];
        }
    }
    [BHCustomTabBarUtility recordTabViews:tabViews];

    NSArray <NSString *> *visibleOrder = [BHCustomTabBarUtility visiblePageIDsInOrder];

    NSMutableDictionary <NSString *, id> *entriesByPage = [NSMutableDictionary new];
    for (id<T1AppNavigationTabEntry> entry in entries) {
        NSString *page = BHT_scribePageForEntry(entry);
        if (page && !entriesByPage[page]) {
            entriesByPage[page] = entry;
        }
    }

    // Not customised yet: show the default set (Home, Search, Notifications, Chats)
    // in that order, hiding everything else the app builds.
    if (!visibleOrder) {
        NSMutableArray *defaultEntries = [NSMutableArray new];
        for (NSString *pageID in [BHCustomTabBarUtility defaultVisiblePageIDs]) {
            id entry = entriesByPage[pageID];
            if (entry) {
                [defaultEntries addObject:entry];
            }
        }
        return defaultEntries;
    }

    NSSet <NSString *> *hiddenBars = [NSSet setWithArray:[BHCustomTabBarUtility hiddenPageIDs]];

    NSMutableArray *orderedEntries = [NSMutableArray new];
    NSMutableSet *placed = [NSMutableSet new];
    for (NSString *pageID in visibleOrder) {
        id entry = entriesByPage[pageID];
        if (entry && ![placed containsObject:pageID]) {
            [orderedEntries addObject:entry];
            [placed addObject:pageID];
        }
    }

    // Preserve any tab the editor doesn't know about (unless the user hid it),
    // keeping it in its original position at the end.
    for (id<T1AppNavigationTabEntry> entry in entries) {
        NSString *page = BHT_scribePageForEntry(entry);
        if (!page || [placed containsObject:page] || [hiddenBars containsObject:page]) {
            continue;
        }
        [orderedEntries addObject:entry];
    }

    return orderedEntries;
}

// The single ordered spine that feeds both the tab buttons and their content, so
// filtering/reordering here keeps taps mapped to the right panel.
%hook T1TabbedAppNavigationViewController

- (void)setVisibleTabEntries:(NSArray *)entries {
    %orig(BHT_orderedTabEntries(entries));
}

%end

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
