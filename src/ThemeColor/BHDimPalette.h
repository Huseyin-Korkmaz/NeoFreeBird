//
//  BHDimPalette.h
//  NeoFreeBird
//
//  Created by nyaathea
//

#import <UIKit/UIKit.h>

@interface BHDimPalette : NSObject

/**
 * Whether Twitter's active palette is a dark one (Dim or Lights Out).
 */
+ (BOOL)isDarkMode;

/**
 * Whether Twitter's active palette is Dim specifically (as opposed to Lights Out).
 */
+ (BOOL)isDimMode;

/**
 * Twitter's current app background color, read straight from the active
 * TAEColorPalette so it always matches the app chrome (white in Light,
 * #15202b in Dim, black in Lights Out).
 */
+ (UIColor *)currentBackgroundColor;

@end
