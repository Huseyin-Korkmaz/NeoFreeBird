//
//  GeneralSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/GeneralSettingsViewController.h"
#import "Headers/TWHeaders.h"

extern void BHT_applyHideCustomTimelinesSetting(void);

@implementation GeneralSettingsViewController

- (NSString *)pageKey {
    return @"general";
}

- (void)switchChanged:(UISwitch *)sender {
    [super switchChanged:sender];
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if ([key isEqualToString:@"hide_custom_timelines"]) {
        BHT_applyHideCustomTimelinesSetting();
    }
}

@end
