//
//  BHTHelpers.h
//  BHTwitter
//
//  Created by BandarHelal
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>
#import "TAEHeaders.h"

typedef UIFont *(*BH_BaseImp)(id,SEL,...);
static NSMutableDictionary<NSString*, NSValue*>* originalFontsIMP;

@interface NSParagraphStyle ()
+ (NSWritingDirection)_defaultWritingDirection;
@end

@interface SFSafariViewController ()
- (NSURL *)initialURL;
@end

static void BH_changeTwitterColor(NSInteger colorID) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    TAEColorSettings *colorSettings = [objc_getClass("TAEColorSettings") sharedSettings];

    [defaults setObject:@(colorID) forKey:@"T1ColorSettingsPrimaryColorOptionKey"];
    [colorSettings setPrimaryColorOption:colorID];
}
static UIImage *BH_imageFromView(UIView *view) {
    TAEColorSettings *colorSettings = [objc_getClass("TAEColorSettings") sharedSettings];
    bool opaque = [colorSettings.currentColorPalette isDark] ? true : false;
    UIGraphicsBeginImageContextWithOptions(view.frame.size, opaque, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:false];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

static  UIFont * _Nullable BH_getDefaultFont(UIFont *font) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"custom_fonts"]) {
        // https://stackoverflow.com/a/20515367/16619237
        UIFontDescriptorSymbolicTraits fontDescriptorSymbolicTraits = font.fontDescriptor.symbolicTraits;
        BOOL isBold = (fontDescriptorSymbolicTraits & UIFontDescriptorTraitBold) != 0;

        if ([[NSUserDefaults standardUserDefaults] objectForKey:isBold ? @"bhtwitter_font_2" : @"bhtwitter_font_1"]) {
            NSString *fontName = [[NSUserDefaults standardUserDefaults] objectForKey:isBold ? @"bhtwitter_font_2" : @"bhtwitter_font_1"];
            return [UIFont fontWithName:fontName size:font.pointSize];
        }
        return nil;
    }
    return nil;
}
static BOOL isDeviceLanguageRTL() {
    return [NSParagraphStyle _defaultWritingDirection] == NSWritingDirectionRightToLeft;
}
static BOOL is_iPad() {
    if ([(NSString *)[UIDevice currentDevice].model hasPrefix:@"iPad"]) {
        return YES;
    }
    return NO;
}

// https://github.com/julioverne/MImport/blob/0275405812ff41ed2ca56e98f495fd05c38f41f2/mimporthook/MImport.xm#L59
static UIViewController * _Nullable _topMostController(UIViewController * _Nonnull cont) {
    UIViewController *topController = cont;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    if ([topController isKindOfClass:[UINavigationController class]]) {
        UIViewController *visible = ((UINavigationController *)topController).visibleViewController;
        if (visible) {
            topController = visible;
        }
    }
    return (topController != cont ? topController : nil);
}
static UIViewController * _Nonnull topMostController() {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *next = nil;
    while ((next = _topMostController(topController)) != nil) {
        topController = next;
    }
    return topController;
}


@interface UIImageView (TwitterLogo)
- (id)initWithImage:(UIImage *)image;
- (void)setImage:(UIImage *)image;
@end

// Forward declaration for TweetSourceHelper (implemented in SourceLabels.x)
@interface TweetSourceHelper : NSObject
+ (void)fetchSourceForTweetID:(NSString *)tweetID;
+ (void)initializeCookiesWithRetry;
+ (void)cleanupTimersForBackground;
@end

// Forward declaration for WKWebView
@interface WKWebView (BHTwitter)
@end

// Block type definitions for compatibility
typedef void (^VoidBlock)(void);
typedef id (^UnknownBlock)(void);

// Forward declaration for the BHTwitter accent color function
extern UIColor *BHTCurrentAccentColor(void);
