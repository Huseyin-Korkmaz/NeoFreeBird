//
//  BHColorThemeViewController.m
//  BHTwitter
//
//  Created by Bandar Alruwaili on 10/12/2023.
//  Modified by actuallyaridan on 25/05/2025.
//
//  Clones the native accent picker (ColorThemePickerItem): an evenly-spread row
//  of filled colour circles with a ring on the selected one.
//

#import "BHColorThemeViewController.h"
#import "BHColorSwatchControl.h"
#import "Core/BHTBundle.h"
#import "Headers/TWHeaders.h"
#import "ThemeColor/BHDimPalette.h"
#import <UIKit/UIKit.h>
#import "Core/TwitterChirpFont.h"

// Single source of truth for the selected accent: prefer our override, then
// Twitter's own primary color option, then the default (blue = option 1). Mirrors
// BHTCurrentAccentColor so the default swatch shows selected before any change.
static NSInteger BHCurrentSelectedColorOption(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"bh_color_theme_selectedColor"]) {
        return [defaults integerForKey:@"bh_color_theme_selectedColor"];
    }
    // Twitter stores its default accent (blue) as option 0, and resets to 0 on
    // launch; our swatches are options 1-6, so map 0 (or unset) to blue.
    NSInteger option = [defaults integerForKey:@"T1ColorSettingsPrimaryColorOptionKey"];
    return option >= 1 ? option : 1;
}

// Twitter's six accent options, and their colours from the app's own palette.
static const NSUInteger kAccentOptionCount = 6;

static UIColor *BHNativeAccentColor(NSUInteger option) {
    id palette = [[[objc_getClass("TAEColorSettings") sharedSettings] currentColorPalette] colorPalette];
    UIColor *color = [palette primaryColorForOption:option];
    return [color isKindOfClass:[UIColor class]] ? color : nil;
}

@interface BHColorThemeViewController ()
@property (nonatomic, strong) NSMutableArray<BHColorSwatchControl *> *swatches;
@end

@implementation BHColorThemeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.view.backgroundColor = [BHDimPalette currentBackgroundColor];

    UILabel *detail = [UILabel new];
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    detail.text = [[BHTBundle sharedBundle] localizedStringForKey:@"THEME_SETTINGS_NAVIGATION_DETAIL"];
    detail.font = [TwitterChirpFont(TwitterFontStyleRegular) fontWithSize:13];
    detail.textColor = [UIColor secondaryLabelColor];
    detail.numberOfLines = 0;
    [self.view addSubview:detail];

    // Evenly-spread row of swatches, matching the native picker's flex layout.
    UIStackView *row = [[UIStackView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFillEqually;
    // Fill so each swatch control takes the full row height (a real tap target);
    // the circle stays centered inside it.
    row.alignment = UIStackViewAlignmentFill;
    [self.view addSubview:row];

    self.swatches = [NSMutableArray new];
    for (NSUInteger option = 1; option <= kAccentOptionCount; option++) {
        BHColorSwatchControl *swatch = [[BHColorSwatchControl alloc] init];
        swatch.translatesAutoresizingMaskIntoConstraints = NO;
        swatch.colorID = option;
        swatch.isAccessibilityElement = YES;
        swatch.accessibilityLabel = [[BHTBundle sharedBundle] localizedStringForKey:[NSString stringWithFormat:@"THEME_OPTION_%lu", (unsigned long)option]];
        [swatch setSwatchColor:BHNativeAccentColor(option)];
        [swatch addTarget:self action:@selector(swatchTapped:) forControlEvents:UIControlEventTouchUpInside];
        [row addArrangedSubview:swatch];
        [self.swatches addObject:swatch];
    }

    [NSLayoutConstraint activateConstraints:@[
        [detail.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [detail.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [detail.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [row.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:16],
        [row.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [row.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [row.heightAnchor constraintEqualToConstant:52]
    ]];

    [self refreshSelection];
}

- (void)refreshSelection {
    NSInteger selected = BHCurrentSelectedColorOption();
    for (BHColorSwatchControl *swatch in self.swatches) {
        [swatch setSwatchSelected:(swatch.colorID == selected)];
    }
}

- (void)swatchTapped:(BHColorSwatchControl *)swatch {
    [[NSUserDefaults standardUserDefaults] setInteger:swatch.colorID forKey:@"bh_color_theme_selectedColor"];
    BH_changeTwitterColor(swatch.colorID);

    [self refreshSelection];
    [self reapplyTabBarAccent];
}

// Re-tint the live tab bar icons to the new accent.
- (void)reapplyTabBarAccent {
    Class t1TabBarVCClass = NSClassFromString(@"T1TabBarViewController");
    if (!t1TabBarVCClass) return;

    UIWindow *window = nil;
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            if ([scene.delegate respondsToSelector:@selector(window)]) {
                window = [(id)scene.delegate window];
            } else {
                for (UIWindow *w in [(id)scene windows]) {
                    if (w.isKeyWindow) { window = w; break; }
                }
            }
            if (window) break;
        }
    }
    if (!window) return;

    NSMutableArray *stack = [NSMutableArray arrayWithObject:window.rootViewController];
    while (stack.count) {
        UIViewController *vc = stack.firstObject;
        [stack removeObjectAtIndex:0];
        if ([vc isKindOfClass:t1TabBarVCClass] &&
            [vc respondsToSelector:@selector(tabViews)]) {
            for (id tab in [vc valueForKey:@"tabViews"]) {
                if ([tab respondsToSelector:@selector(bh_applyCurrentThemeToIcon)]) {
                    [tab performSelector:@selector(bh_applyCurrentThemeToIcon)];
                }
            }
        }
        if (vc.presentedViewController) [stack addObject:vc.presentedViewController];
        if ([vc isKindOfClass:[UINavigationController class]])
            [stack addObjectsFromArray:((UINavigationController *)vc).viewControllers];
        if ([vc isKindOfClass:[UITabBarController class]])
            [stack addObjectsFromArray:((UITabBarController *)vc).viewControllers];
        [stack addObjectsFromArray:vc.childViewControllers];
    }
}

@end
