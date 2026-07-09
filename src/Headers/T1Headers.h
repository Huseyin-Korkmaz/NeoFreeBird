//
//  T1Headers.h
//  BHTwitter
//
//  Created by BandarHelal
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "Download/BHDownload.h"
#import "JGProgressHUD/JGProgressHUD.h"
#import "TFNHeaders.h"
#import "TFSHeaders.h"

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

@interface T1StandardStatusAttachmentViewAdapter : NSObject
@property (nonatomic, assign, readonly) NSUInteger attachmentType;
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

@interface T1SettingsViewController : UIViewController
@property (nonatomic, strong) TFNItemsDataViewControllerBackingStore *backingStore;
@property (nonatomic, strong) NSArray *sections;
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
