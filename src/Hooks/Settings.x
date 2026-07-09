//
//  Settings.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static UIFont * _Nonnull BH_remapFont(UIFont *origFont) {
    UIFont *newFont = BH_getDefaultFont(origFont);
    return newFont != nil ? newFont : origFont;
}

// MARK: BHTwitter settings entry

// The settings root (revamp and legacy alike) is a diffable TFNItemsDataViewController
// subclass. A section is just an array of items, so a one-item section carrying our
// TFNSettingsNavigationItem is inserted near the top. The generic controller also backs
// the settings sub-pages, so the entry is only added to the root (the first controller in
// its navigation stack) and only once per controller instance.
static void BHT_insertNeoFreeBirdSettings(TFNItemsDataViewController *settingsVC, id account) {
    if (settingsVC.navigationController.viewControllers.firstObject != settingsVC) {
        return;
    }

    static const void *insertedKey = &insertedKey;
    if ([objc_getAssociatedObject(settingsVC, insertedKey) boolValue]) {
        return;
    }

    UIColor *iconColor;
    if (@available(iOS 12.0, *)) {
        if (settingsVC.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            iconColor = [UIColor systemGray2Color];
        } else {
            iconColor = [UIColor secondaryLabelColor];
        }
    } else {
        iconColor = [UIColor secondaryLabelColor];
    }

    UIImage *twitterIcon = [UIImage tfn_vectorImageNamed:@"twitter" fitsSize:CGSizeMake(20, 20) fillColor:iconColor];

    TFNSettingsNavigationItem *bhtwitter = [[objc_getClass("TFNSettingsNavigationItem") alloc] initWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_TITLE"] detail:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_DETAIL"] iconName:nil controllerFactory:^UIViewController *{
        return [BHTManager BHTSettingsWithAccount:account];
    }];

    if (twitterIcon) {
        [bhtwitter setValue:twitterIcon forKey:@"icon"];
    }

    NSUInteger sectionIndex = (settingsVC.sections.count > 0) ? 1 : 0;
    [settingsVC insertSection:@[bhtwitter] atIndex:sectionIndex];

    objc_setAssociatedObject(settingsVC, insertedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%hook T1GenericSettingsViewController
- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    BHT_insertNeoFreeBirdSettings(self, self.account);
}
%end

%hook T1SettingsViewController
- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    BHT_insertNeoFreeBirdSettings(self, self.account);
}
%end

// MARK: Change font
%hook UIFontPickerViewController
- (void)viewWillAppear:(BOOL)arg1 {
    %orig(arg1);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"CUSTOM_FONTS_NAVIGATION_BUTTON_TITLE"] style:UIBarButtonItemStylePlain target:self action:@selector(customFontsHandler)];
}
%new - (void)customFontsHandler {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Fonts/AddedFontCache.plist"]) {
        NSAttributedString *AttString = [[NSAttributedString alloc] initWithString:[[BHTBundle sharedBundle] localizedStringForKey:@"CUSTOM_FONTS_MENU_TITLE"] attributes:@{
            NSFontAttributeName: [BHTManager menuTitleFont],
            NSForegroundColorAttributeName: UIColor.labelColor
        }];
        TFNActiveTextItem *title = [[%c(TFNActiveTextItem) alloc] initWithTextModel:[[%c(TFNAttributedTextModel) alloc] initWithAttributedString:AttString] activeRanges:nil];

        NSMutableArray *actions = [[NSMutableArray alloc] init];
        [actions addObject:title];

        NSDictionary *plistDictionary = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Fonts/AddedFontCache.plist"]] options:NSPropertyListImmutable format:NULL error:nil];
        [plistDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            @try {
                NSString *fontName = ((NSArray *)[obj valueForKey:@"psNames"]).firstObject;
                TFNActionItem *fontAction = [%c(TFNActionItem) actionItemWithTitle:fontName action:^{
                    if (self.configuration.includeFaces) {
                        [self setSelectedFontDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:@{
                            UIFontDescriptorNameAttribute: fontName
                        }]];
                    } else {
                        [self setSelectedFontDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:@{
                            UIFontDescriptorFamilyAttribute: fontName
                        }]];
                    }
                    [self.delegate fontPickerViewControllerDidPickFont:self];
                }];
                [actions addObject:fontAction];
            } @catch (NSException *exception) {
                NSLog(@"Unable to find installed fonts /n reason: %@", exception.reason);
            }
        }];

        TFNMenuSheetViewController *alert = [[%c(TFNMenuSheetViewController) alloc] initWithActionItems:[NSArray arrayWithArray:actions]];
        [alert tfnPresentedCustomPresentFromViewController:self animated:YES completion:nil];
    } else {
        UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"BHTwitter" message:[[BHTBundle sharedBundle] localizedStringForKey:@"CUSTOM_FONTS_TUT_ALERT_MESSAGE"] preferredStyle:UIAlertControllerStyleAlert];

        [errAlert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"INSTALL_IFONT_BUTTON_TITLE"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.apple.com/sa/app/ifont-find-install-any-font/id1173222289"] options:@{} completionHandler:nil];
        }]];
        [errAlert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"OK_BUTTON_TITLE"] style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:errAlert animated:true completion:nil];
    }
}
%end

// Every named getter on TFNUIDefaultFontGroup (bodyFont, title1Font, navigationTitleFont, ...)
// computes a size and dynamically dispatches to one of these five methods, the only ones that
// actually build a UIFont. Remapping at the root covers the whole font surface.
%hook TFNUIDefaultFontGroup
- (UIFont *)fontOfSize:(CGFloat)size {
    UIFont *origFont = %orig;
    return BH_remapFont(origFont);
}
- (UIFont *)mediumFontOfSize:(CGFloat)size {
    UIFont *origFont = %orig;
    return BH_remapFont(origFont);
}
- (UIFont *)boldFontOfSize:(CGFloat)size {
    UIFont *origFont = %orig;
    return BH_remapFont(origFont);
}
- (UIFont *)heavyFontOfSize:(CGFloat)size {
    UIFont *origFont = %orig;
    return BH_remapFont(origFont);
}
- (UIFont *)monospacedDigitFontOfSize:(CGFloat)size weight:(CGFloat)weight {
    UIFont *origFont = %orig;
    return BH_remapFont(origFont);
}
%end

%hook HBForceCepheiPrefs
+ (BOOL)forceCepheiPrefsWhichIReallyNeedToAccessAndIKnowWhatImDoingISwear {
    return YES;
}
%end
