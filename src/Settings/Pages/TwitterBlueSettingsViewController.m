//
//  TwitterBlueSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/TwitterBlueSettingsViewController.h"
#import "Settings/ModernSettingsCells.h"
#import "Headers/TWHeaders.h"
#import "Core/BHTBundle.h"

@implementation TwitterBlueSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 60;
    [self.tableView registerClass:[ModernSettingsSimpleButtonCell class] forCellReuseIdentifier:@"SimpleButtonCell"];
}

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_TWITTER_BLUE_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_TWITTER_BLUE_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{ @"key": @"undo_tweet", @"titleKey": @"UNDO_TWEET_OPTION_TITLE", @"subtitleKey": @"UNDO_TWEET_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"hide_promoted", @"titleKey": @"HIDE_ADS_OPTION_TITLE", @"subtitleKey": @"HIDE_ADS_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"hide_premium_offer", @"titleKey": @"HIDE_PREMIUM_OFFER_OPTION", @"subtitleKey": @"HIDE_PREMIUM_OFFER_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"titleKey": @"THEME_OPTION_TITLE", @"action": @"showThemeViewController:", @"type": @"button" },
        @{ @"titleKey": @"APP_ICON_TITLE", @"action": @"showBHAppIconViewController:", @"type": @"button" },
        @{ @"titleKey": @"CUSTOM_TAB_BAR_OPTION_TITLE", @"action": @"showCustomTabBarVC:", @"type": @"button" }
    ];
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

@end
