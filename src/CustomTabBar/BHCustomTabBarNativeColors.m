//
//  BHCustomTabBarNativeColors.m
//  NeoFreeBird
//

#import "BHCustomTabBarNativeColors.h"
#import <objc/runtime.h>

@interface UIColor (BHNativeTokens)
+ (id)twitterColors;
+ (id)tfnuiColors;
@end

@interface NSObject (BHNativeTokens)
- (UIColor *)subscriptionMarketingFeatureCardBackgroundColor;
- (UIColor *)subscriptionMarketingFeatureCardShadowColor;
- (UIColor *)tabCustomizationInactiveGridCellContainerBackgroundColor;
- (UIColor *)backgroundColor;
- (UIColor *)navigationBarShadowColor;
- (UIColor *)textColor;
+ (UIColor *)itemColor;
@end

static UIColor *BHResolve(id provider, SEL selector, UIColor *fallback) {
    if (provider && [provider respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIColor *color = [provider performSelector:selector];
#pragma clang diagnostic pop
        if ([color isKindOfClass:[UIColor class]]) {
            return color;
        }
    }
    return fallback;
}

static id BHTwitterColors(void) {
    return [UIColor respondsToSelector:@selector(twitterColors)] ? [UIColor twitterColors] : nil;
}

static id BHTFNUIColors(void) {
    return [UIColor respondsToSelector:@selector(tfnuiColors)] ? [UIColor tfnuiColors] : nil;
}

UIColor *BHCustomTabBarCardBackgroundColor(void) {
    return BHResolve(BHTwitterColors(), @selector(subscriptionMarketingFeatureCardBackgroundColor), [UIColor systemBackgroundColor]);
}

UIColor *BHCustomTabBarInactiveCardBackgroundColor(void) {
    return BHResolve(BHTwitterColors(), @selector(tabCustomizationInactiveGridCellContainerBackgroundColor), [UIColor secondarySystemBackgroundColor]);
}

UIColor *BHCustomTabBarCardShadowColor(void) {
    return BHResolve(BHTwitterColors(), @selector(subscriptionMarketingFeatureCardShadowColor), [UIColor blackColor]);
}

UIColor *BHCustomTabBarShadowColor(void) {
    return BHCustomTabBarCardShadowColor();
}

UIColor *BHCustomTabBarIconColor(void) {
    return BHResolve(objc_getClass("T1TabView"), @selector(itemColor), [UIColor labelColor]);
}

UIColor *BHCustomTabBarTitleColor(void) {
    return BHResolve(BHTFNUIColors(), @selector(textColor), [UIColor labelColor]);
}

UIColor *BHCustomTabBarScreenBackgroundColor(void) {
    return BHResolve(BHTwitterColors(), @selector(backgroundColor), [UIColor systemBackgroundColor]);
}

UIColor *BHCustomTabBarSeparatorColor(void) {
    return BHResolve(BHTwitterColors(), @selector(navigationBarShadowColor), [UIColor separatorColor]);
}
