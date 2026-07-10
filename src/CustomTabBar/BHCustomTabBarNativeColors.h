//
//  BHCustomTabBarNativeColors.h
//  NeoFreeBird
//
//  Resolves the native tab-customization colour tokens (from
//  [UIColor twitterColors] / [UIColor tfnuiColors] / [T1TabView itemColor]),
//  falling back to system colours if a selector is missing after an app update.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIColor *BHCustomTabBarCardBackgroundColor(void);          // grid tile background
UIColor *BHCustomTabBarInactiveCardBackgroundColor(void);  // fixed (Home) tile background
UIColor *BHCustomTabBarCardShadowColor(void);              // grid tile shadow
UIColor *BHCustomTabBarShadowColor(void);                  // preview cell shadow
UIColor *BHCustomTabBarIconColor(void);                    // tab icon fill
UIColor *BHCustomTabBarTitleColor(void);                   // grid tile title
UIColor *BHCustomTabBarScreenBackgroundColor(void);        // screen background
UIColor *BHCustomTabBarSeparatorColor(void);               // preview hairline separator

NS_ASSUME_NONNULL_END
