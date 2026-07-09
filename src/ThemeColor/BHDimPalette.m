//
//  BHDimPalette.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "ThemeColor/BHDimPalette.h"
#import <objc/runtime.h>

@protocol BHTAEColorPalette <NSObject>
- (UIColor *)backgroundColor;
@end

@interface TAETwitterColorPaletteSettingInfo : NSObject
@property (nonatomic, readonly) BOOL isDark;
- (id <BHTAEColorPalette>)colorPalette;
@end

@interface TAEColorSettings : NSObject
+ (instancetype)sharedSettings;
- (TAETwitterColorPaletteSettingInfo *)currentColorPalette;
@end

@implementation BHDimPalette

+ (TAETwitterColorPaletteSettingInfo *)currentPaletteInfo {
    Class settingsClass = objc_getClass("TAEColorSettings");
    if (![settingsClass respondsToSelector:@selector(sharedSettings)]) {
        return nil;
    }

    id settings = [settingsClass sharedSettings];
    if (![settings respondsToSelector:@selector(currentColorPalette)]) {
        return nil;
    }

    return [settings currentColorPalette];
}

+ (BOOL)isDarkMode {
    TAETwitterColorPaletteSettingInfo *info = [self currentPaletteInfo];
    if ([info respondsToSelector:@selector(isDark)]) {
        return [info isDark];
    }

    if (@available(iOS 13.0, *)) {
        return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return NO;
}

+ (UIColor *)currentBackgroundColor {
    TAETwitterColorPaletteSettingInfo *info = [self currentPaletteInfo];
    if ([info respondsToSelector:@selector(colorPalette)]) {
        id <BHTAEColorPalette> palette = [info colorPalette];
        if ([palette respondsToSelector:@selector(backgroundColor)]) {
            UIColor *background = [palette backgroundColor];
            if (background) {
                return background;
            }
        }
    }
    return [UIColor systemBackgroundColor];
}

+ (BOOL)isDimMode {
    if (![self isDarkMode]) {
        return NO;
    }

    // Dim and Lights Out share the "dark" palette; only the background color
    // tells them apart (Dim is #15202b, Lights Out is pure black).
    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
    if ([[self currentBackgroundColor] getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return (red + green + blue) > 0.01;
    }
    return YES;
}

@end
