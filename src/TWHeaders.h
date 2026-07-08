//
//  TWHeaders.h
//  BHTwitter
//
//  Created by BandarHelal
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreServices/CoreServices.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import <SafariServices/SafariServices.h>
#import "BHDownload/BHDownload.h"
#import "CustomTabBar/BHCustomTabBarUtility.h"
#import "JGProgressHUD/JGProgressHUD.h"
#import "SAMKeychain/keychain.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import "ffmpeg/FFmpegKit.h"
#import "ffmpeg/FFprobeKit.h"
#import "ffmpeg/MediaInformationSession.h"
#import "ffmpeg/MediaInformation.h"
#import <WebKit/WebKit.h>


typedef UIFont *(*BH_BaseImp)(id,SEL,...);
static NSMutableDictionary<NSString*, NSValue*>* originalFontsIMP;
static id _PasteboardChangeObserver;
static NSDictionary<NSString*, NSArray<NSString*>*> *trackingParams;
static NSString *_lastCopiedURL;

@interface T1AppDelegate : UIResponder <UIApplicationDelegate>
@property(retain, nonatomic) UIWindow *window;
+ (id)launchTransitionProvider;
@end


@interface TTMAssetVideoFile: NSObject
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, assign, readonly) CGFloat duration;

@end

@interface TTMAssetVoiceRecording: TTMAssetVideoFile
@property (nonatomic, strong, readwrite) NSNumber *totalDurationMillis;
@end

@interface T1MediaAttachmentsViewCell: UICollectionViewCell
@property (nonatomic, strong, readwrite) id attachment;
@property (nonatomic, strong) UIButton *uploadButton;
@end

@interface T1MediaAttachmentsViewCell () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@end

@interface NSParagraphStyle ()
+ (NSWritingDirection)_defaultWritingDirection;
@end

@interface SFSafariViewController ()
- (NSURL *)initialURL;
@end

@interface TFNTwitterAccount : NSObject
@property (nonatomic, strong) NSString *displayFullName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayUsername;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) id scribe;
@end

@interface T1StandardStatusAttachmentViewAdapter : NSObject
@property (nonatomic, assign, readonly) NSUInteger attachmentType;
@end

@interface TFNTableView : UITableView
- (void)setShowsVerticalScrollIndicator:(BOOL)arg1;
@end

@interface TFNDataViewController : UIViewController
@property(readonly, nonatomic) TFNTableView *tableView;
@property(readonly, nonatomic) NSString *adDisplayLocation;
@end

@interface TFNItemsDataViewController : TFNDataViewController
@property(copy, nonatomic) NSArray *sections;
- (id)itemAtIndexPath:(id)arg1;
@end

@interface TFNItemsDataViewControllerBackingStore: NSObject
- (void)insertSection:(id)section atIndex:(NSUInteger)index;
- (void)insertItem:(id)item atIndexPath:(NSIndexPath *)indexPath;
- (void)_tfn_insertSection:(id)section atIndex:(NSUInteger)index;
- (void)_tfn_insertItem:(id)item atIndexPath:(NSIndexPath *)indexPath;
@end

@interface T1TabView : UIView
@property(readonly, nonatomic) UILabel *titleLabel;
@property(readonly, nonatomic) long long panelID;
@property(copy, nonatomic) NSString *scribePage;
@end

@interface T1TabBarViewController : UIViewController
@property(copy, nonatomic) NSArray *tabViews;
@end

@interface T1GenericSettingsViewController: UIViewController
@property (nonatomic, strong) TFNItemsDataViewControllerBackingStore *backingStore;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) TFNTwitterAccount *account;
@end

@interface TFNNavigationController : UINavigationController
@end

@interface TTSSearchTypeaheadViewController : TFNItemsDataViewController
- (void)clearActionControlWantsClear:(id)arg1;
@end
@interface T1SearchTypeaheadViewController : TFNItemsDataViewController
- (void)clearActionControlWantsClear:(id)arg1;
@end

@interface TAEStandardFontGroup : NSObject
+ (instancetype)sharedFontGroup;
- (UIFont *)headline2BoldFont;
@end

@interface TFNActionItem : NSObject
+ (instancetype)cancelActionItemWithAction:(void (^)(void))arg1;
+ (instancetype)cancelActionItemWithTitle:(NSString *)arg1;
+ (instancetype)actionItemWithTitle:(NSString *)arg1 action:(void (^)(void))arg2;
+ (instancetype)actionItemWithTitle:(NSString *)arg1 imageName:(NSString *)arg2 action:(void (^)(void))arg3;
+ (instancetype)actionItemWithTitle:(NSString *)arg1 subtitle:(NSString *)arg2 imageName:(NSString *)arg3 action:(void (^) (void))arg4;
@end

@interface TFNAttributedTextModel : NSObject
@property(copy, nonatomic) NSAttributedString *attributedString;
- (instancetype)initWithAttributedString:(NSMutableAttributedString *)arg;
@end

@interface TFNAttributedTextView : UIView
- (void)setTextModel:(id)model;
@end

@interface TFNActiveTextItem : NSObject
- (instancetype)initWithTextModel:(id)arg activeRanges:(id)arg1;
@end

@interface TFNMenuSheetViewController : TFNItemsDataViewController
@property(nonatomic, assign, readwrite) BOOL shouldPresentAsMenu;
@property(retain, nonatomic) UIView *sourceView;
- (instancetype)initWithTitle:(NSString *)sheetTitle actionItems:(NSArray *)actionItems;
- (instancetype)initWithMessage:(NSString *)sheetMessage actionItems:(NSArray *)actionItems;
- (instancetype)initWithActionItems:(NSArray *)actionItems;
- (instancetype)initWithTitle:(NSString *)sheetTitle titleStyle:(long long)sheetTitleStyle message:(NSString *)sheetMessage messageIconName:(id)sheetMessageIconName actionItemSections:(NSArray *)actionItemSections;
- (void)tfnPresentedCustomPresentFromViewController:(id)arg1 animated:(BOOL)arg2 completion:(void (^) (void))arg3;
@end

@interface T1SettingsViewController : UIViewController
@property (nonatomic, strong) TFNItemsDataViewControllerBackingStore *backingStore;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) TFNTwitterAccount *account;
@end

@interface TFNSettingsNavigationItem : NSObject
- (instancetype)initWithTitle:(NSString *)arg1 detail:(NSString *)arg2 iconName:(NSString *)arg3 controllerFactory:(UIViewController* (^)(void))arg4;
- (instancetype)initWithTitle:(NSString *)arg1 detail:(NSString *)arg2 controllerFactory:(UIViewController* (^)(void))arg4;
@end

@interface TFNTextCell: UITableViewCell
@end

@interface TFNButton : UIButton
+ (id)buttonWithImage:(id)arg1 style:(long long)arg2 sizeClass:(long long)arg3;
@end

@interface T1ProfileActionButtonsView : UIView
@property(nonatomic, retain) UIView *_innerContentView;
@property(nonatomic, retain) UIView *_outerContentView;
@end

@interface T1ProfileHeaderView : UIView
@property(readonly, nonatomic) T1ProfileActionButtonsView *actionButtonsView;
@end

@interface T1ProfileUserViewModel : NSObject
@property(readonly, copy, nonatomic) NSString *location;
@property(readonly, copy, nonatomic) NSString *fullName;
@property(readonly, copy, nonatomic) NSString *username;
@property(readonly, copy, nonatomic) NSString *bio;
@property(readonly, copy, nonatomic) NSString *url;
@end

@interface T1ProfileHeaderViewController: UIViewController
- (void)copyButtonHandler;
@property(retain, nonatomic) T1ProfileUserViewModel *viewModel;
@end

@protocol T1StatusInlineActionButtonDelegate <NSObject>
@end
@protocol TTAStatusInlineActionButtonDelegate <NSObject>
@end

@interface TTAStatusInlineShareButton : UIView
@property(nonatomic) __weak id <T1StatusInlineActionButtonDelegate> delegate;
@end

@interface TTAStatusInlineReplyButton : UIView
@property(nonatomic) __weak id <T1StatusInlineActionButtonDelegate> delegate;
@end

@interface T1PersistentComposeViewController : UIViewController
@property(readonly, nonatomic) id statusViewModel;
@end

@protocol TTACoreStatusViewEventHandler <NSObject>
@end

@interface T1StatusCell : UITableViewCell <TTACoreStatusViewEventHandler>
@end

@interface TFSTwitterEntityMediaVideoVariant : NSObject
@property(readonly, copy, nonatomic) NSString *contentType;
@property(readonly, copy, nonatomic) NSString *url;
@end

@interface TFSTwitterEntityMediaVideoInfo : NSObject
@property(readonly, copy, nonatomic) NSArray *variants;
@property(readonly, copy, nonatomic) NSString *primaryUrl;
@end

@interface TFSTwitterEntityMedia : NSObject
@property(readonly, nonatomic) TFSTwitterEntityMediaVideoInfo *videoInfo;
@property(readonly, copy, nonatomic) NSString *mediaURL;
@property(nonatomic, assign, readonly) NSInteger mediaType; // 1 = photo, 2 = GIF, 3 = video
@end

@interface TFSTwitterEntitySet : NSObject
@property(readonly, copy, nonatomic) NSArray *media;
@end

@interface T1StatusInlineActionsView : UIView <T1StatusInlineActionButtonDelegate>
@property(readonly, nonatomic) id viewModel;
@property(nonatomic) id delegate;
@end

@interface TTAStatusInlineActionsView : UIView <TTAStatusInlineActionButtonDelegate>
@property(readonly, nonatomic) id viewModel;
@property(nonatomic) id delegate;
@end

@interface T1StandardStatusView : UIView
@property(nonatomic) __weak id <TTACoreStatusViewEventHandler> eventHandler;
@property(readonly, nonatomic) UIView *visibleInlineActionsView;
@end

@interface T1TweetDetailsFocalStatusView : UIView
@property(nonatomic) __weak id <TTACoreStatusViewEventHandler> eventHandler;
@end

@interface T1ConversationFocalStatusView : UIView
@property(nonatomic) __weak id <TTACoreStatusViewEventHandler> eventHandler;
- (void)layoutSubviews;
@property(nonatomic, readonly) id viewModel;
- (void)enumerateSubviewsRecursively:(void (^)(UIView *))block;
@end

@interface T1TweetComposeViewController : UIViewController
@end

@interface T1PlayerMediaEntitySessionProducible : NSObject
@property(readonly, nonatomic) TFSTwitterEntityMedia *mediaEntity;
@end

@protocol T1PlayerSessionProducible <NSObject>
@end

@interface T1PlayerSessionProducer : NSObject
@property(readonly, nonatomic) id <T1PlayerSessionProducible> sessionProducible;
@end


@protocol T1InlineMediaViewModel <NSObject>
@property(nonatomic, readonly) T1PlayerSessionProducer *playerSessionProducer;
@end

@interface T1InlineMediaView : UIView
@property (retain, nonatomic) id <T1InlineMediaViewModel> viewModel;
@property (readonly, nonatomic) UIImageView *previewImageView;
@property (retain, nonatomic) UIView *playerIconView;
@property (nonatomic, assign, readwrite) NSUInteger playerIconViewType;
@end

@interface T1DirectMessageEntryBaseCell: UICollectionViewCell
@property(nonatomic, readonly) UIImage *profileImage;
@end

@interface T1DirectMessageEntryMediaCell : T1DirectMessageEntryBaseCell
@property (nonatomic, strong) JGProgressHUD *hud;
// @property (nonatomic, strong) NSURL *ffmepgExportURL;
- (void)mediaUploadProgress:(id)arg1;
@property(nonatomic, readonly) T1InlineMediaView *inlineMediaView; // @synthesize inlineMediaView;
- (void)updateConstraints;
- (_Bool)accessibilityActivate;
- (void)dealloc;
- (void)layoutSubviews;
- (instancetype)initWithFrame:(struct CGRect)arg1;
- (void)DownloadHandler;
@end

@interface T1DirectMessageEntryMediaCell () <BHDownloadDelegate, UIContextMenuInteractionDelegate>
@end

@protocol TFNTwitterStatusBanner <NSObject>
@end

@interface TFNTwitterURTTimelineStatusBanner : NSObject <TFNTwitterStatusBanner>
@end

@interface TFNTwitterURTTimelineStatusTopicBanner : TFNTwitterURTTimelineStatusBanner
@end

@interface T1URTTimelineStatusItemViewModel : NSObject
@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) _Bool isPromoted;
@property(nonatomic, retain) id <TFNTwitterStatusBanner> banner;
@end

@interface TFNTwitterStatus : NSObject
@property(readonly, nonatomic) NSDictionary *scribeParameters;
@property(readonly, nonatomic) _Bool isPromoted;
@property(readonly, nonatomic) TFSTwitterEntitySet *entities;
@property(nonatomic, copy) NSString *fromUserName;
@property(nonatomic, assign) NSInteger statusID;
- (id)init;
@end

@interface TFNTwitter : NSObject
+ (instancetype)sharedTwitter;
@property(readonly, nonatomic) NSArray *accounts;
@end

@interface T1HostViewController : UIViewController
+ (instancetype)sharedHostViewController;
- (id)currentAccount;
@end

@interface T1BaseWebViewController : UIViewController
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithAccount:(id)account;
- (void)setRootURL:(NSURL *)url;
- (void)setCurrentURL:(NSURL *)url;
@property(nonatomic, readonly) NSURL *currentURL;
- (WKWebView *)webView;
@end

@interface T1WebViewController : T1BaseWebViewController
- (instancetype)initWithRootURL:(NSURL *)rootURL
                        account:(id)account
             shouldAuthenticate:(BOOL)shouldAuthenticate
      shouldPresentAsNativePage:(BOOL)shouldPresentAsNativePage
                   sourceStatus:(id)sourceStatus
                scribeComponent:(id)scribeComponent
               scribeParameters:(id)scribeParameters;
@property(nonatomic, strong) id account;
- (BOOL)doesURLResultTypeOpenInWebview:(long long)resultType;
@end

@interface UIViewController (TFNPresentation)
- (void)tfn_dismissAnimated:(id)sender;
- (void)tfn_presentFromViewController:(UIViewController *)viewController animated:(BOOL)animated;
@end

@interface TFSTwitterEntityURL : NSObject
@property(readonly, copy, nonatomic) NSString *expandedURL;
@end

@interface T1StatusBodyTextView : UIView
@property(readonly, nonatomic) id viewModel; // @synthesize viewModel=_viewModel;
@end

@interface TFNTitleView: UIView
+ (instancetype)titleViewWithTitle:(NSString *)title subtitle:(NSString *)subTitle;
@end

@interface _TtC10TwitterURT25URTTimelineTrendViewModel : NSObject
@property(nonatomic, readonly) NSDictionary *scribeItem;
@end

@class FLEXAlert, FLEXAlertAction;

typedef void (^FLEXAlertReveal)(void);
typedef void (^FLEXAlertBuilder)(FLEXAlert *make);
typedef FLEXAlert * _Nonnull (^FLEXAlertStringProperty)(NSString * _Nullable);
typedef FLEXAlert * _Nonnull (^FLEXAlertStringArg)(NSString * _Nullable);
typedef FLEXAlert * _Nonnull (^FLEXAlertTextField)(void(^configurationHandler)(UITextField *textField));
typedef FLEXAlertAction * _Nonnull (^FLEXAlertAddAction)(NSString *title);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionStringProperty)(NSString * _Nullable);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionProperty)(void);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionBOOLProperty)(BOOL);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionHandler)(void(^handler)(NSArray<NSString *> *strings));

@interface FLEXAlert : NSObject

/// Shows a simple alert with one button which says "Dismiss"
+ (void)showAlert:(NSString * _Nullable)title message:(NSString * _Nullable)message from:(UIViewController *)viewController;

/// Shows a simple alert with no buttons and only a title, for half a second
+ (void)showQuickAlert:(NSString *)title from:(UIViewController *)viewController;

/// Construct and display an alert
+ (void)makeAlert:(FLEXAlertBuilder)block showFrom:(UIViewController *)viewController;
/// Construct and display an action sheet-style alert
+ (void)makeSheet:(FLEXAlertBuilder)block
         showFrom:(UIViewController *)viewController
           source:(id)viewOrBarItem;

/// Construct an alert
+ (UIAlertController *)makeAlert:(FLEXAlertBuilder)block;
/// Construct an action sheet-style alert
+ (UIAlertController *)makeSheet:(FLEXAlertBuilder)block;

/// Set the alert's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) FLEXAlertStringProperty title;
/// Set the alert's message.
///
/// Call in succession to append strings to the message.
@property (nonatomic, readonly) FLEXAlertStringProperty message;
/// Add a button with a given title with the default style and no action.
@property (nonatomic, readonly) FLEXAlertAddAction button;
/// Add a text field with the given (optional) placeholder text.
@property (nonatomic, readonly) FLEXAlertStringArg textField;
/// Add and configure the given text field.
///
/// Use this if you need to more than set the placeholder, such as
/// supply a delegate, make it secure entry, or change other attributes.
@property (nonatomic, readonly) FLEXAlertTextField configuredTextField;

@end

@interface FLEXAlertAction : NSObject

/// Set the action's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) FLEXAlertActionStringProperty title;
/// Make the action destructive. It appears with red text.
@property (nonatomic, readonly) FLEXAlertActionProperty destructiveStyle;
/// Make the action cancel-style. It appears with a bolder font.
@property (nonatomic, readonly) FLEXAlertActionProperty cancelStyle;
/// Enable or disable the action. Enabled by default.
@property (nonatomic, readonly) FLEXAlertActionBOOLProperty enabled;
/// Give the button an action. The action takes an array of text field strings.
@property (nonatomic, readonly) FLEXAlertActionHandler handler;
/// Access the underlying UIAlertAction, should you need to change it while
/// the encompassing alert is being displayed. For example, you may want to
/// enable or disable a button based on the input of some text fields in the alert.
/// Do not call this more than once per instance.
@property (nonatomic, readonly) UIAlertAction *action;

@end
@interface FLEXManager : NSObject
+ (instancetype)sharedManager;
- (void)showExplorer;
- (void)hideExplorer;
- (void)toggleExplorer;
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"en_font"]) {
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

@interface T1ConversationFooterTextView : TFNAttributedTextView
@property(nonatomic, readonly) id viewModel;
- (void)updateFooterTextView;
@end

@interface TFNBarButtonItemButtonV1 : UIView
@property (nonatomic, strong) UIColor *tintColor;
@end

// T1ProfileFriendsFollowingViewModel interface for unrounded follower/following counts
@interface T1ProfileFriendsFollowingViewModel : NSObject
- (id)_t1_followCountTextWithLabel:(id)arg1 singularLabel:(id)arg2 count:(id)arg3 highlighted:(_Bool)arg4;
@end

// Forward declaration for TweetSourceHelper to be used in early hooks
@interface TweetSourceHelper : NSObject
+ (void)fetchSourceForTweetID:(NSString *)tweetID;
+ (void)timeoutFetchForTweetID:(NSTimer *)timer;
+ (void)handleAppForeground:(NSNotification *)notification;
+ (NSDictionary *)fetchCookies;
+ (void)cacheCookies:(NSDictionary *)cookies;
+ (NSDictionary *)loadCachedCookies;
+ (void)handleClearCacheNotification:(NSNotification *)notification;
+ (void)pruneSourceCachesIfNeeded;
+ (void)logDebugInfo:(NSString *)message;
+ (void)initializeCookiesWithRetry;
+ (void)updateFooterTextViewsForTweetID:(NSString *)tweetID;
+ (void)cleanupTimersForBackground;
@end

// Forward declaration for WKWebView
@interface WKWebView (BHTwitter)
@end

// Forward declare TTAStatusBodySelectableContentTextView
@interface TTAStatusBodySelectableContentTextView : UITextView
@property(retain, nonatomic) NSAttributedString *originalAttributedText;
- (void)setAttributedText:(NSAttributedString *)attributedText;
- (void)BHT_setTranslatedText:(NSAttributedString *)translatedText;
- (void)BHT_restoreOriginalText;
- (BOOL)BHT_isShowingTranslatedText;
@end

// Block type definitions for compatibility
typedef void (^VoidBlock)(void);
typedef id (^UnknownBlock)(void);

// Forward declare T1ColorSettings and its private method to satisfy the compiler
@interface T1ColorSettings : NSObject
+ (void)_t1_applyPrimaryColorOption;
+ (void)_t1_updateOverrideUserInterfaceStyle;
@end

// Forward declaration for the immersive view controller
@interface T1ImmersiveFullScreenViewController : UIViewController
- (void)immersiveViewController:(id)immersiveViewController showHideNavigationButtons:(_Bool)showButtons;
- (void)playerViewController:(id)playerViewController playerStateDidChange:(NSInteger)state;
@end

// Now declare the category, after the main interface is known
@interface T1ImmersiveFullScreenViewController (BHTwitter)
- (BOOL)BHT_findAndPrepareTimestampLabelForVC:(T1ImmersiveFullScreenViewController *)activePlayerVC;
@end

// Forward declaration for the BHTwitter accent color function
extern UIColor *BHTCurrentAccentColor(void);

// UIImage category for TFN vector image methods
@interface UIImage (TFNAdditions)
+ (id)tfn_vectorImageNamed:(id)arg1 fitsSize:(struct CGSize)arg2 fillColor:(id)arg3;
+ (BOOL)tfn_vectorImageExistsNamed:(id)arg1 fitsSize:(struct CGSize)arg2 size:(out struct CGSize *)arg3;
+ (id)tfn_vectorImageNamed:(id)arg1 highContrastVariantNamed:(id)arg2 fitsSize:(struct CGSize)arg3 fillColor:(id)arg4;
+ (id)tfn_vectorImageNamed:(id)arg1 height:(double)arg2 fillColor:(id)arg3;
+ (void)tfn_vectorImageSetOverrideContainersDirectoryURL:(NSURL *)arg1;
+ (NSURL *)tfn_vectorImageOverrideContainersDirectoryURL;
+ (void)tfn_vectorImageSetSearchDirectoryURLs:(NSArray *)arg1;
+ (NSArray *)tfn_vectorImageSearchDirectoryURLs;
+ (void)tfn_vectorImageSetOverrideContainerName:(NSString *)arg1;
+ (NSString *)tfn_vectorImageOverrideContainerName;
@end
