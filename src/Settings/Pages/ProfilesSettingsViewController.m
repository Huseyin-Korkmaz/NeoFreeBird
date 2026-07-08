//
//  ProfilesSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/ProfilesSettingsViewController.h"
#import "Headers/TWHeaders.h"
#import "Core/BHTBundle.h"

@implementation ProfilesSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_PROFILES_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_PROFILES_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[
        @{ @"key": @"follow_con", @"titleKey": @"FOLLOW_CONFIRM_OPTION_TITLE", @"subtitleKey": @"FOLLOW_CONFIRM_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"CopyProfileInfo", @"titleKey": @"COPY_PROFILE_INFO_OPTION_TITLE", @"subtitleKey": @"COPY_PROFILE_INFO_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"bio_translate", @"titleKey": @"BIO_TRANSLATE_OPTION_TITLE", @"subtitleKey": @"BIO_TRANSLATE_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"disableMediaTab", @"titleKey": @"DISABLE_MEDIA_TAB_OPTION_TITLE", @"subtitleKey": @"DISABLE_MEDIA_TAB_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"disableArticles", @"titleKey": @"DISABLE_ARTICLES_OPTION_TITLE", @"subtitleKey": @"DISABLE_ARTICLES_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"disableHighlights", @"titleKey": @"DISABLE_HIGHLIGHTS_OPTION_TITLE", @"subtitleKey": @"DISABLE_HIGHLIGHTS_OPTION_DETAIL_TITLE", @"default": @YES, @"type": @"toggle" },
        @{ @"key": @"hide_follow_button", @"titleKey": @"HIDE_FOLLOW_BUTTON_TITLE", @"subtitleKey": @"HIDE_FOLLOW_BUTTON_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"restore_follow_button", @"titleKey": @"RESTORE_FOLLOW_BUTTON_TITLE", @"subtitleKey": @"RESTORE_FOLLOW_BUTTON_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" },
        @{ @"key": @"square_avatars", @"titleKey": @"SQUARE_AVATARS_TITLE", @"subtitleKey": @"SQUARE_AVATARS_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
    ];
}

- (void)switchChanged:(UISwitch *)sender {
    [super switchChanged:sender];
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if ([key isEqualToString:@"square_avatars"]) {
        [self showRestartRequiredAlert:@"RESTART_REQUIRED_ALERT_MESSAGE"];
    }
}

- (void)showRestartRequiredAlert:(NSString *)messageKey {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"RESTART_REQUIRED_ALERT_TITLE"]
                                                                   message:[[BHTBundle sharedBundle] localizedStringForKey:messageKey]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"NOT_NOW_BUTTON_TITLE"] style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"RESTART_NOW_BUTTON_TITLE"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {exit(0);}]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
