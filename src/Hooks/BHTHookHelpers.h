//
//  BHTHookHelpers.h
//  NeoFreeBird
//
//  Shared imports and helpers for the hook files in src/Hooks.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h> // For objc_msgSend and objc_msgSend_stret
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import <dlfcn.h>
#import "SAMKeychain/AuthViewController.h"
#import "Colours/Colours.h"
#import "Core/BHTManager.h"
#import "Core/BHTSettings.h"
#import "ThemeColor/BHDimPalette.h"
#import <math.h>
#import "Core/BHTBundle.h"
#import "LegacyLogin/BHTLegacyLoginViewController.h"
#import "Headers/TWHeaders.h"
#import "SAMKeychain/SAMKeychain.h"
#import "CustomTabBar/BHCustomTabBarUtility.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "Settings/ModernSettingsViewController.h"
#import "Download/BHDownloadInlineButton.h"

// Recursive view traversal (BHTHookHelpers.m)
void BH_EnumerateSubviewsRecursively(UIView *view, void (^block)(UIView *currentView));

// View controller lookup helpers (BHTHookHelpers.m)
UIViewController *getViewControllerForView(UIView *view);
BOOL isViewInsideT1ProfileHeaderViewController(UIView *view);
BOOL isViewInsideDashHostingController(UIView *view);

// Theme engine synchronisation (Theme.x)
void BHT_UpdateAllTabBarIcons(void);
void BHT_applyThemeToWindow(UIWindow *window);
void BHT_ensureThemingEngineSynchronized(BOOL forceSynchronize);

// Restored tweet source labels, keyed by tweet ID (SourceLabels.x)
extern NSMutableDictionary *tweetSources;

// Web session cookie harvesting (WebCreateTweet.x)
void BHT_prewarmWebCookiesIfNeeded(void);
void BHT_maybeHandleHarvestWebView(__unsafe_unretained id webViewController);
id BHT_accountForAuthenticatedWebView(void);
