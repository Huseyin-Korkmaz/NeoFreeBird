//
//  BHTdownloadManager.h
//  BHT
//
//  Created by BandarHelal on 24/12/1441 AH.
//

#import "Headers/TWHeaders.h"


@interface BHTManager : NSObject
+ (NSString *)getDownloadingPersent:(float)per;
+ (void)cleanCache;
+ (NSString *)getVideoQuality:(NSString *)url;
+ (id)sharedFontGroup;
+ (UIFont *)menuTitleFont;
+ (bool)isDMVideoCell:(T1InlineMediaView *)view;
+ (BOOL)doesContainDigitsOnly:(NSString *)string;
+ (UIViewController *)BHTSettingsWithAccount:(TFNTwitterAccount *)twAccount;
+ (void)showSaveVC:(NSURL *)url;
+ (void)save:(NSURL *)url;
+ (MediaInformation *)getM3U8Information:(NSURL *)mediaURL;
+ (TFNMenuSheetViewController *)newFFmpegDownloadSheet:(MediaInformation *)mediaInformation downloadingURL:(NSURL *)downloadingURL progressView:(JGProgressHUD *)hud;

+ (BOOL)DownloadingVideos;
+ (BOOL)DirectSave;
+ (BOOL)UndoTweet;
+ (BOOL)NoHistory;
+ (BOOL)BioTranslate;
+ (BOOL)LikeConfirm;
+ (BOOL)TweetConfirm;
+ (BOOL)FollowConfirm;
+ (BOOL)HidePromoted;
+ (BOOL)HideTopics;
+ (BOOL)DisableVODCaptions;
+ (BOOL)Padlock;
+ (BOOL)OldStyle;
+ (BOOL)bypassAgeVerification;
+ (BOOL)FLEX;
+ (BOOL)autoHighestLoad;
+ (BOOL)disableSensitiveTweetWarnings;
+ (BOOL)showScrollIndicator;
+ (BOOL)CopyProfileInfo;
+ (BOOL)tweetToImage;
+ (BOOL)hideSpacesBar;
+ (BOOL)disableRTL;
+ (BOOL)alwaysOpenSafari;
+ (BOOL)replyInWebView;
+ (BOOL)hideWhoToFollow;
+ (BOOL)hideTopicsToFollow;
+ (BOOL)hideBlueVerified;
+ (BOOL)hideViewCount;
+ (BOOL)hidePremiumOffer;
+ (BOOL)hideTrendVideos;
+ (BOOL)forceTweetFullFrame;
+ (BOOL)stripTrackingParams;
+ (BOOL)stopHidingTabBar;
+ (BOOL)hideBookmarkButton;
+ (BOOL)hideDownvoteButton;
+ (BOOL)customVoice;
+ (BOOL)RestoreTweetLabels;
+ (BOOL)disableMediaTab;
+ (BOOL)disableArticles;
+ (BOOL)hideCustomTimelines;
+ (BOOL)hideTrends;
+ (BOOL)disableHighlights;

+ (BOOL)hideGrokAnalyze;
+ (BOOL)restoreTwitterNames;
+ (BOOL)isTwitterBranded;
+ (BOOL)hideFollowButton;
+ (BOOL)restoreFollowButton;
+ (BOOL)squareAvatars;
+ (BOOL)restoreVideoTimestamp;
+ (BOOL)classicTabBarEnabled;
+ (BOOL)restoreTabLabels;

+ (BOOL)replySorting;

+ (BOOL)restoreReplyContext;

@end
