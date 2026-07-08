//
//  Settings.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static UIFont * _Nullable TAEStandardFontGroupReplacement(UIFont *self, SEL _cmd, CGFloat arg1, CGFloat arg2) {
    BH_BaseImp orig  = originalFontsIMP[NSStringFromSelector(_cmd)].pointerValue;
    NSUInteger nArgs = [[self class] instanceMethodSignatureForSelector:_cmd].numberOfArguments;
    UIFont *origFont;
    switch (nArgs) {
        case 2:
            origFont = orig(self, _cmd);
            break;
        case 3:
            origFont = orig(self, _cmd, arg1);
            break;
        case 4:
            origFont = orig(self, _cmd, arg1, arg2);
            break;
        default:
            // Should not be reachable, as it was verified before swizzling
            origFont = orig(self, _cmd);
            break;
    };

    UIFont *newFont  = BH_getDefaultFont(origFont);
    return newFont != nil ? newFont : origFont;
}
static void batchSwizzlingOnClass(Class cls, NSArray<NSString*>*origSelectors, IMP newIMP){
    for (NSString *sel in origSelectors) {
        SEL origSel = NSSelectorFromString(sel);
        Method origMethod = class_getInstanceMethod(cls, origSel);
        if (origMethod != NULL) {
            IMP oldImp = class_replaceMethod(cls, origSel, newIMP, method_getTypeEncoding(origMethod));
            [originalFontsIMP setObject:[NSValue valueWithPointer:oldImp] forKey:sel];
        } else {
            NSLog(@"[BHTwitter] Can't find method (%@) in Class (%@)", sel, NSStringFromClass(cls));
        }
    }
}
// MARK: BHTwitter settings
%hook T1GenericSettingsViewController
- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    if ([self.sections count] == 1) {
        TFNItemsDataViewControllerBackingStore *backingStore = self.backingStore;

        // Use Twitter's internal vector image system to get the Twitter bird icon
        UIImage *twitterIcon = nil;

        // Choose color based on interface style
        UIColor *iconColor;
        if (@available(iOS 12.0, *)) {
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                iconColor = [UIColor systemGray2Color];
            } else {
                iconColor = [UIColor secondaryLabelColor];
            }
        } else {
            iconColor = [UIColor secondaryLabelColor];
        }

        // Twitter vector image
        twitterIcon = [UIImage tfn_vectorImageNamed:@"twitter" fitsSize:CGSizeMake(20, 20) fillColor:iconColor];

        // Create the settings item
        TFNSettingsNavigationItem *bhtwitter = [[%c(TFNSettingsNavigationItem) alloc] initWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_TITLE"] detail:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_DETAIL"] iconName:nil controllerFactory:^UIViewController *{
            return [BHTManager BHTSettingsWithAccount:self.account];
        }];

        // Set our Twitter icon
        if (twitterIcon) {
            [bhtwitter setValue:twitterIcon forKey:@"_icon"];
        }

        if ([backingStore respondsToSelector:@selector(insertSection:atIndex:)]) {
            [backingStore insertSection:0 atIndex:1];
        } else {
            [backingStore _tfn_insertSection:0 atIndex:1];
        }
        if ([backingStore respondsToSelector:@selector(insertItem:atIndexPath:)]) {
            [backingStore insertItem:bhtwitter atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        } else {
            [backingStore _tfn_insertItem:bhtwitter atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
    }
}
%end

%hook T1SettingsViewController
- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    if ([self.sections count] == 2) {
        TFNItemsDataViewControllerBackingStore *DataViewControllerBackingStore = self.backingStore;
        [DataViewControllerBackingStore insertSection:0 atIndex:1];
        [DataViewControllerBackingStore insertItem:@"Row 0 " atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [DataViewControllerBackingStore insertItem:@"Row1" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 1) {

        TFNTextCell *Tweakcell = [[%c(TFNTextCell) alloc] init];
        [Tweakcell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [Tweakcell.textLabel setText:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_DETAIL"]];
        return Tweakcell;
    } else if (indexPath.section == 0 && indexPath.row == 0) {

        TFNTextCell *Settingscell = [[%c(TFNTextCell) alloc] init];
        [Settingscell setBackgroundColor:[UIColor clearColor]];
        Settingscell.textLabel.textColor = [UIColor colorWithRed:0.40 green:0.47 blue:0.53 alpha:1.0];
        [Settingscell.textLabel setText:[[BHTBundle sharedBundle] localizedStringForKey:@"NFB_SETTINGS_TITLE"]];
        return Settingscell;
    }


    return %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section]== 0 && [indexPath row]== 1) {
        [self.navigationController pushViewController:[BHTManager BHTSettingsWithAccount:self.account] animated:true];
    } else {
        return %orig;
    }
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

        NSPropertyListFormat plistFormat;
        NSMutableDictionary *plistDictionary = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Fonts/AddedFontCache.plist"]] options:NSPropertyListImmutable format:&plistFormat error:nil];
        [plistDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            @try {
                NSString *fontName = ((NSMutableArray *)[[plistDictionary valueForKey:key] valueForKey:@"psNames"]).firstObject;
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

        [errAlert addAction:[UIAlertAction actionWithTitle:@"iFont application" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.apple.com/sa/app/ifont-find-install-any-font/id1173222289"] options:@{} completionHandler:nil];
        }]];
        [errAlert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"OK_BUTTON_TITLE"] style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:errAlert animated:true completion:nil];
    }
}
%end

%hook TAEStandardFontGroup
+ (TAEStandardFontGroup *)sharedFontGroup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *fontsMethods = [NSMutableArray arrayWithArray:@[]];

        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList([self class], &methodCount);
        for (unsigned int i = 0; i < methodCount; ++i) {
            Method method = methods[i];
            SEL sel = method_getName(method);
            NSString *selStr = NSStringFromSelector(sel);

            NSMethodSignature *methodSig = [self instanceMethodSignatureForSelector:sel];
            if (strcmp(methodSig.methodReturnType, @encode(void)) == 0) {
                // Only add methods that return an object
                continue;
            } else if (methodSig.numberOfArguments == 2) {
                // - (id)bodyFont; ...
                [fontsMethods addObject:selStr];
            } else if (methodSig.numberOfArguments == 3
                       && strcmp([methodSig getArgumentTypeAtIndex:2], @encode(CGFloat)) == 0) {
                // - (id)fontOfSize:(CGFloat); ...
                [fontsMethods addObject:selStr];
            } else if (methodSig.numberOfArguments == 4
                       && strcmp([methodSig getArgumentTypeAtIndex:2], @encode(CGFloat)) == 0
                       && strcmp([methodSig getArgumentTypeAtIndex:3], @encode(CGFloat)) == 0) {
                // - (id)monospacedDigitalFontOfSize:(CGFloat) weight:(CGFloat); ...
                [fontsMethods addObject:selStr];
            } else {
                NSLog(@"[BHTwitter] Method (%@) with unknown signiture (%@) in TAEStandardFontGroup", selStr, methodSig);
            }
        }
        free(methods);

        originalFontsIMP = [NSMutableDictionary new];
        batchSwizzlingOnClass([self class], [fontsMethods copy], (IMP)TAEStandardFontGroupReplacement);
    });
    return %orig;
}
%end

%hook HBForceCepheiPrefs
+ (BOOL)forceCepheiPrefsWhichIReallyNeedToAccessAndIKnowWhatImDoingISwear {
    return YES;
}
%end
