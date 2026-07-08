//
//  DebugSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/DebugSettingsViewController.h"
#import "Headers/TWHeaders.h"

@implementation DebugSettingsViewController

- (NSString *)pageTitleKey {
    return @"MODERN_SETTINGS_DEBUG_TITLE";
}

- (NSString *)pageSubtitleKey {
    return @"MODERN_SETTINGS_DEBUG_SUBTITLE";
}

- (void)buildSettingsList {
    self.toggles = @[ @{ @"key": @"flex_twitter", @"titleKey": @"FLEX_OPTION_TITLE", @"subtitleKey": @"FLEX_OPTION_DETAIL_TITLE", @"default": @NO, @"type": @"toggle" }
    ];
}

- (void)switchChanged:(UISwitch *)sender {
    [super switchChanged:sender];
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if ([key isEqualToString:@"flex_twitter"]) {
        if (sender.isOn) {
            [[objc_getClass("FLEXManager") sharedManager] showExplorer];
        } else {
            [[objc_getClass("FLEXManager") sharedManager] hideExplorer];
        }
    }
}

@end
