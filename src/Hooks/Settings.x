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

static const void *BHTSettingsEntryKey = &BHTSettingsEntryKey;
static const void *BHTSettingsRootKey = &BHTSettingsRootKey;

static BOOL BHT_isSettingsClass(UIViewController *viewController) {
    return [viewController isKindOfClass:objc_getClass("T1GenericSettingsViewController")] || [viewController isKindOfClass:objc_getClass("T1SettingsViewController")];
}

// The generic controller backs the root and every sub-page alike, and settings is
// pushed onto the main navigation stack (home at its root), so the root page is the
// first settings-class controller in the stack — sub-pages always have another one
// beneath them.
static BOOL BHT_settingsVCIsRoot(TFNItemsDataViewController *settingsVC) {
    for (UIViewController *viewController in settingsVC.navigationController.viewControllers) {
        if (viewController == settingsVC) {
            return YES;
        }

        if (BHT_isSettingsClass(viewController)) {
            return NO;
        }
    }

    return NO;
}

static BOOL BHT_sectionsContainNeoFreeBirdEntry(NSArray *sections) {
    for (id section in sections) {
        if (![section isKindOfClass:[NSArray class]]) {
            continue;
        }

        for (id entry in (NSArray *)section) {
            if (objc_getAssociatedObject(entry, BHTSettingsEntryKey)) {
                return YES;
            }
        }
    }

    return NO;
}

static TFNSettingsNavigationItem *BHT_makeNeoFreeBirdSettingsItem(TFNItemsDataViewController *settingsVC) {
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

    TFNTwitterAccount *account = [(T1GenericSettingsViewController *)settingsVC account];
    TFNSettingsNavigationItem *bhtwitter = [[objc_getClass("TFNSettingsNavigationItem") alloc] initWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_TITLE"] detail:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_DETAIL"] iconName:nil controllerFactory:^UIViewController *{
        return [BHTManager BHTSettingsWithAccount:account];
    }];

    if (twitterIcon) {
        [bhtwitter setValue:twitterIcon forKey:@"icon"];
    }

    objc_setAssociatedObject(bhtwitter, BHTSettingsEntryKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return bhtwitter;
}

static NSArray *BHT_sectionsByInsertingEntry(TFNItemsDataViewController *settingsVC, NSArray *sections) {
    NSMutableArray *newSections = [sections mutableCopy] ?: [NSMutableArray array];
    [newSections insertObject:@[BHT_makeNeoFreeBirdSettingsItem(settingsVC)] atIndex:0];
    return newSections;
}

// The settings root rebuilds its sections from the page model whenever the account
// updates, and appearing kicks off an async settings fetch that triggers exactly such
// a rebuild — a one-shot insert gets discarded moments after the view appears. But the
// first rebuild also runs before the controller joins the navigation stack, where
// root-ness can't be determined yet. So the root is recognised and tagged in
// viewWillAppear, which inserts the entry imperatively to repair the build that
// already ran; the rebuild transform below re-adds it to every later snapshot.
static void BHT_insertNeoFreeBirdSettingsIfRoot(TFNItemsDataViewController *settingsVC) {
    if (!BHT_settingsVCIsRoot(settingsVC)) {
        return;
    }

    objc_setAssociatedObject(settingsVC, BHTSettingsRootKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (BHT_sectionsContainNeoFreeBirdEntry(settingsVC.sections)) {
        return;
    }

    settingsVC.sections = BHT_sectionsByInsertingEntry(settingsVC, settingsVC.sections);
}

static NSArray *BHT_sectionsWithNeoFreeBirdEntry(TFNItemsDataViewController *settingsVC, NSArray *sections) {
    if (!BHT_isSettingsClass(settingsVC)) {
        return sections;
    }

    if (![objc_getAssociatedObject(settingsVC, BHTSettingsRootKey) boolValue]) {
        return sections;
    }

    if (BHT_sectionsContainNeoFreeBirdEntry(sections)) {
        return sections;
    }

    return BHT_sectionsByInsertingEntry(settingsVC, sections);
}

%hook T1GenericSettingsViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    BHT_insertNeoFreeBirdSettingsIfRoot(self);
}
%end

%hook T1SettingsViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    BHT_insertNeoFreeBirdSettingsIfRoot(self);
}
%end

// Every sections rebuild runs through this transform right before setSections:,
// so hooking it on the base class covers both settings roots.
%hook TFNItemsDataViewController
- (NSArray *)updatedSections:(NSArray *)sections forStyle:(NSInteger)style {
    NSArray *updatedSections = %orig;
    return BHT_sectionsWithNeoFreeBirdEntry(self, updatedSections);
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
