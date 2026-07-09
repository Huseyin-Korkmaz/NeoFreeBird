//
//  T1Headers.h
//  BHTwitter
//
//  Created by BandarHelal
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>
#import "Download/BHDownload.h"
#import "JGProgressHUD/JGProgressHUD.h"
#import "TFNHeaders.h"
#import "TFSHeaders.h"

@interface T1AppDelegate : UIResponder <UIApplicationDelegate>
@property(retain, nonatomic) UIWindow *window;
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

@interface T1StandardStatusAttachmentViewAdapter : NSObject
@property (nonatomic, assign, readonly) NSUInteger attachmentType;
@end

@interface T1TabView : UIView
@property(readonly, nonatomic) UILabel *titleLabel;
@property(readonly, nonatomic) long long panelID;
@property(copy, nonatomic) NSString *scribePage;
@property(retain, nonatomic) UIColor *iconColor;
@property(readonly, nonatomic, getter=isSelected) BOOL selected;
- (void)_t1_updateTitleLabel;
- (void)_t1_updateImageViewAnimated:(BOOL)animated;
@end

@interface T1TabBarViewController : UIViewController
@property(copy, nonatomic) NSArray *tabViews;
@end

// The settings root is a collection/diffable TFNItemsDataViewController subclass in 12.3.
// T1GenericSettingsViewController backs the "settings revamp" root (and, driven by a page
// model, the sub-pages); T1SettingsViewController is the legacy fallback root.
@interface T1GenericSettingsViewController: TFNItemsDataViewController
@property (nonatomic, strong) TFNTwitterAccount *account;
@end

@interface T1SettingsViewController: TFNItemsDataViewController
@property (nonatomic, strong) TFNTwitterAccount *account;
@end

@interface T1ProfileActionButtonSpec : NSObject
@property(readonly, copy, nonatomic) UIView *(^buttonCreationBlock)(void);
- (instancetype)initWithPosition:(NSUInteger)position priority:(NSUInteger)priority visibilityBlock:(BOOL (^)(double))visibilityBlock buttonCreationBlock:(UIView *(^)(void))buttonCreationBlock;
@end

@interface T1ProfileUserViewModel : NSObject
@property(readonly, copy, nonatomic) NSString *location;
@property(readonly, copy, nonatomic) NSString *fullName;
@property(readonly, copy, nonatomic) NSString *username;
@property(readonly, copy, nonatomic) NSString *bio;
@property(readonly, copy, nonatomic) NSString *url;
@end

@interface T1ProfileHeaderViewController: UIViewController
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

@class BHDownloadInlineButton;

// DM media message container (DMConversation.MessageAttachmentView)
@interface _TtC14DMConversation21MessageAttachmentView : UIView
@property (nonatomic, strong) UIContextMenuInteraction *downloadMenuInteraction;
@property (nonatomic, strong) BHDownloadInlineButton *downloadHandler;
@end

@interface _TtC14DMConversation21MessageAttachmentView () <UIContextMenuInteractionDelegate>
@end

// Shared media view (TweetMediaAttachments.MultiMediaView); its carousel
// variant exposes -inlineMediaInfos as well
@interface _TtC21TweetMediaAttachments14MultiMediaView : UIView
@property (nonatomic, readonly) NSArray *inlineMediaInfos;
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
// 12.3 initializer. The 7-arg shouldAuthenticate:/shouldPresentAsNativePage:
// variant below no longer exists on this class (it moved to the Swift
// T1PaymentsWebViewController); it is kept only so existing callers compile,
// and their -instancesRespondToSelector: guards make it a no-op at runtime.
- (instancetype)initWithRootURL:(NSURL *)rootURL
                        account:(id)account
                   sourceStatus:(id)sourceStatus
                scribeComponent:(id)scribeComponent
               scribeParameters:(id)scribeParameters;
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

@interface T1SafariViewController : SFSafariViewController
@property(nonatomic, readonly) NSURL *rootURL;
@end

@interface T1StatusBodyTextView : UIView
@property(readonly, nonatomic) id viewModel; // @synthesize viewModel=_viewModel;
@end

@interface _TtC10TwitterURT25URTTimelineTrendViewModel : NSObject
@property(nonatomic, readonly) NSDictionary *scribeItem;
@end

@interface T1ConversationFooterTextView : TFNAttributedTextView
@property(nonatomic, readonly) id viewModel;
- (void)updateFooterTextView;
@end

// T1ProfileFriendsFollowingViewModel interface for unrounded follower/following counts
@interface T1ProfileFriendsFollowingViewModel : NSObject
- (id)_t1_followCountTextWithLabel:(id)arg1 singularLabel:(id)arg2 count:(id)arg3 highlighted:(_Bool)arg4;
@end

// Forward declare TTAStatusBodySelectableContentTextView
@interface TTAStatusBodySelectableContentTextView : UITextView
@property(retain, nonatomic) NSAttributedString *originalAttributedText;
- (void)setAttributedText:(NSAttributedString *)attributedText;
- (void)BHT_setTranslatedText:(NSAttributedString *)translatedText;
- (void)BHT_restoreOriginalText;
- (BOOL)BHT_isShowingTranslatedText;
@end
