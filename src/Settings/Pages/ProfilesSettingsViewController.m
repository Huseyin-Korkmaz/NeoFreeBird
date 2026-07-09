//
//  ProfilesSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/ProfilesSettingsViewController.h"
#import "Headers/TWHeaders.h"
#import "Core/BHTBundle.h"

extern void BHT_applySquareAvatarsSetting(void);

@implementation ProfilesSettingsViewController

- (NSString *)pageKey {
    return @"profiles";
}

- (void)switchChanged:(UISwitch *)sender {
    [super switchChanged:sender];
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if ([key isEqualToString:@"square_avatars"]) {
        BHT_applySquareAvatarsSetting();
    }
}

@end
