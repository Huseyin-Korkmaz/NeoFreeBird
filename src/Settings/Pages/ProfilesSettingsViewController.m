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

- (NSString *)pageKey {
    return @"profiles";
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
