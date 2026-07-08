//
//  TAEHeaders.h
//  BHTwitter
//
//  Created by BandarHelal
//

#import <UIKit/UIKit.h>

@interface TAEStandardFontGroup : NSObject
+ (instancetype)sharedFontGroup;
- (UIFont *)headline2BoldFont;
@end

@protocol TAEColorPalette
- (id)colorPalette;
- (UIColor *)primaryColorForOption:(NSUInteger)colorOption;
@end

@interface TAETwitterColorPaletteSettingInfo : NSObject
@property(readonly, nonatomic) id <TAEColorPalette> colorPalette;
@property(readonly, nonatomic) _Bool isDark;
@end

@interface TAEColorSettings : NSObject
@property(retain, nonatomic) TAETwitterColorPaletteSettingInfo *currentColorPalette;
- (void)setPrimaryColorOption:(NSInteger)colorOption;
+ (instancetype)sharedSettings;
@end

// Forward declare T1ColorSettings and its private method to satisfy the compiler
@interface T1ColorSettings : NSObject
+ (void)_t1_applyPrimaryColorOption;
+ (void)_t1_updateOverrideUserInterfaceStyle;
@end
