//
//  AppearanceSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/AppearanceSettingsViewController.h"
#import "Settings/ModernSettingsCells.h"
#import "Headers/TWHeaders.h"
#import "Core/BHTBundle.h"
#import "Core/BHTSettings.h"

@interface AppearanceSettingsViewController () <UIFontPickerViewControllerDelegate>
@end

@implementation AppearanceSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 60;
    [self.tableView registerClass:[ModernSettingsSimpleButtonCell class] forCellReuseIdentifier:@"SimpleButtonCell"];
}

- (NSString *)pageKey {
    return @"appearance";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *settingData = self.visibleToggles[indexPath.row];
    if ([settingData[@"type"] isEqualToString:@"button"]) {
        ModernSettingsSimpleButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SimpleButtonCell" forIndexPath:indexPath];
        NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:settingData[@"titleKey"]];
        [cell configureWithTitle:title];
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)showThemeViewController:(NSDictionary *)sender {
    Class BHColorThemeViewControllerClass = objc_getClass("BHColorThemeViewController");
    if (BHColorThemeViewControllerClass) {
        UIViewController *themeVC = [[BHColorThemeViewControllerClass alloc] init];
        if (self.account) {
            [themeVC.navigationItem setTitleView:[objc_getClass("TFNTitleView") titleViewWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"THEME_SETTINGS_NAVIGATION_TITLE"] subtitle:self.account.displayUsername]];
        }
        [self.navigationController pushViewController:themeVC animated:YES];
    }
}

- (void)showBHAppIconViewController:(NSDictionary *)sender {
    Class BHAppIconViewControllerClass = objc_getClass("BHAppIconViewController");
    if (BHAppIconViewControllerClass) {
        UIViewController *appIconVC = [[BHAppIconViewControllerClass alloc] init];
        if (self.account) {
            [appIconVC.navigationItem setTitleView:[objc_getClass("TFNTitleView") titleViewWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"APP_ICON_NAV_TITLE"] subtitle:self.account.displayUsername]];
        }
        [self.navigationController pushViewController:appIconVC animated:YES];
    }
}

- (void)showCustomTabBarVC:(NSDictionary *)sender {
    Class BHCustomTabBarViewControllerClass = objc_getClass("BHCustomTabBarViewController");
    if (BHCustomTabBarViewControllerClass) {
        UIViewController *customTabBarVC = [[BHCustomTabBarViewControllerClass alloc] init];
        if (self.account) {
            [customTabBarVC.navigationItem setTitleView:[objc_getClass("TFNTitleView") titleViewWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"CUSTOM_TAB_BAR_SETTINGS_NAVIGATION_TITLE"] subtitle:self.account.displayUsername]];
        }
        [self.navigationController pushViewController:customTabBarVC animated:YES];
    }
}

- (void)refreshAllTabViewsWithTheming {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow && window.rootViewController) {
            [self refreshTabViewsWithThemingInView:window.rootViewController.view];
        }
    }
}

- (void)refreshTabViewsWithThemingInView:(UIView *)view {
    if ([view isKindOfClass:NSClassFromString(@"T1TabView")]) {
        if ([view respondsToSelector:@selector(_t1_updateImageViewAnimated:)]) {
            [view performSelector:@selector(_t1_updateImageViewAnimated:) withObject:@(NO)];
        }
        if ([view respondsToSelector:@selector(_t1_updateTitleLabel)]) {
            [view performSelector:@selector(_t1_updateTitleLabel)];
        }
        if ([view respondsToSelector:@selector(_t1_layoutForTabBar)]) {
            [view performSelector:@selector(_t1_layoutForTabBar)];
        }
        if ([view respondsToSelector:@selector(_t1_layoutBadgeViewMaximized)]) {
            [view performSelector:@selector(_t1_layoutBadgeViewMaximized)];
        }
        if ([view respondsToSelector:@selector(_t1_layoutBadgeViewMinimized)]) {
            [view performSelector:@selector(_t1_layoutBadgeViewMinimized)];
        }

        if (![BHTSettings boolForKey:@"tab_bar_theming"]) {
            UILabel *titleLabel = [view valueForKey:@"titleLabel"];
            if (titleLabel) {
                titleLabel.textColor = nil;
            }
        }
    }

    for (UIView *subview in view.subviews) {
        [self refreshTabViewsWithThemingInView:subview];
    }
}

- (void)refreshAllTabViews {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow && window.rootViewController) {
            [self refreshTabViewsInView:window.rootViewController.view];
        }
    }
}

- (void)refreshTabViewsInView:(UIView *)view {
    if ([view isKindOfClass:NSClassFromString(@"T1TabView")]) {
        if ([view respondsToSelector:@selector(_t1_updateTitleLabel)]) {
            [view performSelector:@selector(_t1_updateTitleLabel)];
        }
        if ([view respondsToSelector:@selector(_t1_layoutForTabBar)]) {
            [view performSelector:@selector(_t1_layoutForTabBar)];
        }
        if ([view respondsToSelector:@selector(_t1_layoutBadgeViewMaximized)]) {
            [view performSelector:@selector(_t1_layoutBadgeViewMaximized)];
        }

        if (![BHTSettings boolForKey:@"tab_bar_theming"]) {
            UILabel *titleLabel = [view valueForKey:@"titleLabel"];
            if (titleLabel) {
                titleLabel.textColor = nil;
            }
        }
    }

    for (UIView *subview in view.subviews) {
        [self refreshTabViewsInView:subview];
    }
}

- (void)switchChanged:(UISwitch *)sender {
    [super switchChanged:sender];
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if ([key isEqualToString:@"tab_bar_theming"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshAllTabViewsWithTheming];
        });
    } else if ([key isEqualToString:@"restore_tab_labels"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshAllTabViews];
        });
    }
}

- (void)showRegularFontPicker:(NSDictionary *)sender {
    UIFontPickerViewControllerConfiguration *configuration = [[UIFontPickerViewControllerConfiguration alloc] init];
    [configuration setFilteredTraits:UIFontDescriptorClassMask];
    [configuration setIncludeFaces:NO];
    UIFontPickerViewController *fontPicker = [[UIFontPickerViewController alloc] initWithConfiguration:configuration];
    fontPicker.delegate = (id<UIFontPickerViewControllerDelegate>)self;
    objc_setAssociatedObject(fontPicker, @"fontType", @"regular", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.account) {
        [fontPicker.navigationItem setTitleView:[objc_getClass("TFNTitleView") titleViewWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"REQULAR_FONTS_PICKER_OPTION_TITLE"] subtitle:self.account.displayUsername]];
    } else {
        fontPicker.title = [[BHTBundle sharedBundle] localizedStringForKey:@"REQULAR_FONTS_PICKER_OPTION_TITLE"];
    }
    [self.navigationController pushViewController:fontPicker animated:YES];
}

- (void)showBoldFontPicker:(NSDictionary *)sender {
    UIFontPickerViewControllerConfiguration *configuration = [[UIFontPickerViewControllerConfiguration alloc] init];
    [configuration setIncludeFaces:YES];
    [configuration setFilteredTraits:UIFontDescriptorClassModernSerifs];
    [configuration setFilteredTraits:UIFontDescriptorClassMask];
    UIFontPickerViewController *fontPicker = [[UIFontPickerViewController alloc] initWithConfiguration:configuration];
    fontPicker.delegate = (id<UIFontPickerViewControllerDelegate>)self;
    objc_setAssociatedObject(fontPicker, @"fontType", @"bold", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.account) {
        [fontPicker.navigationItem setTitleView:[objc_getClass("TFNTitleView") titleViewWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"BOLD_FONTS_PICKER_OPTION_TITLE"] subtitle:self.account.displayUsername]];
    } else {
        fontPicker.title = [[BHTBundle sharedBundle] localizedStringForKey:@"BOLD_FONTS_PICKER_OPTION_TITLE"];
    }
    [self.navigationController pushViewController:fontPicker animated:YES];
}

- (void)fontPickerViewControllerDidPickFont:(UIFontPickerViewController *)viewController {
    NSString *fontName = viewController.selectedFontDescriptor.fontAttributes[UIFontDescriptorNameAttribute];
    NSString *fontFamily = viewController.selectedFontDescriptor.fontAttributes[UIFontDescriptorFamilyAttribute];
    NSString *fontType = objc_getAssociatedObject(viewController, @"fontType");
    if ([fontType isEqualToString:@"bold"]) {
        [[NSUserDefaults standardUserDefaults] setObject:fontName forKey:@"bhtwitter_font_2"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:fontFamily forKey:@"bhtwitter_font_1"];
    }
    [self updateVisibleToggles];
    [self.tableView reloadData];
    [viewController.navigationController popViewControllerAnimated:YES];
}

@end
