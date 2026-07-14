//
//  BHTHookHelpers.h
//  NeoFreeBird
//
//  Shared imports and helpers for the hook files in src/Hooks.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import <dlfcn.h>
#import "SAMKeychain/AuthViewController.h"
#import "Colours/Colours.h"
#import "Core/BHTManager.h"
#import "Core/BHTSettings.h"
#import "ThemeColor/Palette.h"
#import <math.h>
#import "Core/BHTBundle.h"
#import "LegacyLogin/LegacyLoginViewController.h"
#import "Headers/TWHeaders.h"
#import "SAMKeychain/SAMKeychain.h"
#import "CustomTabBar/CustomTabBarUtility.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "Settings/ModernSettingsViewController.h"
#import "Download/DownloadInlineButton.h"

// Recursive view traversal (BHTHookHelpers.m)
void EnumerateSubviewsRecursively(UIView *view, void (^block)(UIView *currentView));

// TFNDataViewItem unwrapping for timeline section filtering (BHTHookHelpers.m)
id unwrapDataViewItem(id item);

// Live square-avatar restyling (Avatars.x)
void applySquareAvatarsSetting(void);

// Custom theme color re-apply (Theme.x)
void applySelectedThemeColor(void);

// Live pinned-tabs refresh when the hide setting is toggled (Timeline.x)
void applyHideCustomTimelinesSetting(void);

// Whether the account genuinely has a panel's tab, ignoring the forced tab
// gates (FeatureSwitches.x)
BOOL panelIsGenuinelyAvailable(long long panelID);

// Restored tweet source labels, keyed by tweet ID (SourceLabels.x)
extern NSMutableDictionary *tweetSources;

// Web session cookie harvesting (WebCreateTweet.x)
void prewarmWebCookiesIfNeeded(void);
void maybeHandleHarvestWebView(__unsafe_unretained id webViewController);
id accountForAuthenticatedWebView(void);

// Current web-session credentials (auth_token + ct0) for read-only web GraphQL
// requests such as restoring tweet source labels (WebCreateTweet.x)
NSDictionary *currentWebCredentials(void);
