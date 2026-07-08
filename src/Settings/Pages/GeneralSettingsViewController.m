//
//  GeneralSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/GeneralSettingsViewController.h"
#import "Headers/TWHeaders.h"
#import "Core/BHTBundle.h"

@interface GeneralSettingsViewController () <UIFontPickerViewControllerDelegate>
@end

@implementation GeneralSettingsViewController

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

        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"tab_bar_theming"] boolValue]) {
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

        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"tab_bar_theming"] boolValue]) {
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

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_LAYOUT_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_LAYOUT_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
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
    ];
}

- (void)updateAndAnimateChangesForKey:(NSString *)key {
    NSArray *oldVisibleToggles = self.visibleToggles;
    [self updateVisibleToggles];
    NSArray *newVisibleToggles = self.visibleToggles;
    [self.tableView beginUpdates];
    __block NSInteger toggleIndex = -1;
    [oldVisibleToggles enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"key"] isEqualToString:key]) {
            toggleIndex = idx;
            *stop = YES;
        }
    }];
    if (toggleIndex == -1) {
        [self.tableView endUpdates];
        [self.tableView reloadData];
        return;
    }
    NSMutableArray *children = [NSMutableArray array];
    for (NSDictionary *toggleData in self.toggles) {
        if ([toggleData[@"parentKey"] isEqualToString:key]) {
            [children addObject:toggleData];
        }
    }
    if (children.count == 0) {
        [self.tableView endUpdates];
        return;
    }
    BOOL isAdding = newVisibleToggles.count > oldVisibleToggles.count;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (int i = 0; i < children.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:toggleIndex + 1 + i inSection:0]];
    }
    if (isAdding) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
}

- (void)switchChanged:(UISwitch *)sender {
    [super switchChanged:sender];
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if (key) {
        [self updateAndAnimateChangesForKey:key];
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
