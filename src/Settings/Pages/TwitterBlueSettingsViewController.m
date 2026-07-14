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
#import "Core/BHTSettings.h"

@implementation TwitterBlueSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 60;
    [self.tableView registerClass:[ModernSettingsSimpleButtonCell class] forCellReuseIdentifier:@"SimpleButtonCell"];
}

- (NSString *)pageKey {
    return @"twitter_blue";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *settingData = self.visibleToggles[indexPath.row];
    if ([settingData[@"key"] isEqualToString:@"undo_tweet_timeout"]) {
        ModernSettingsCompactButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CompactButtonCell" forIndexPath:indexPath];
        NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:settingData[@"titleKey"]];
        [cell configureWithTitle:title subtitle:[self undoTimeoutSubtitle]];
        return cell;
    }
    if ([settingData[@"type"] isEqualToString:@"button"]) {
        ModernSettingsSimpleButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SimpleButtonCell" forIndexPath:indexPath];
        NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:settingData[@"titleKey"]];
        [cell configureWithTitle:title];
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

// A timeout of 0 reads as "Off"; any positive value shows its seconds.
- (NSString *)labelForTimeout:(NSInteger)seconds {
    if (seconds <= 0) {
        return [[BHTBundle sharedBundle] localizedStringForKey:@"UNDO_TWEET_TIMEOUT_OFF"];
    }
    NSString *format = [[BHTBundle sharedBundle] localizedStringForKey:@"UNDO_TWEET_TIMEOUT_SECONDS"];
    return [NSString stringWithFormat:format, (long)seconds];
}

- (NSString *)undoTimeoutSubtitle {
    return [self labelForTimeout:[BHTSettings integerForKey:@"undo_tweet_timeout"]];
}

// Off plus the same durations Twitter offers in its own premium undo settings.
- (void)showUndoTimeoutPicker:(NSDictionary *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"UNDO_TWEET_TITLE"]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    for (NSNumber *seconds in @[@0, @5, @10, @20, @30, @60]) {
        [alert addAction:[UIAlertAction actionWithTitle:[self labelForTimeout:seconds.integerValue] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[NSUserDefaults standardUserDefaults] setInteger:seconds.integerValue forKey:@"undo_tweet_timeout"];
            [self.tableView reloadData];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"CANCEL_BUTTON_TITLE"] style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
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
