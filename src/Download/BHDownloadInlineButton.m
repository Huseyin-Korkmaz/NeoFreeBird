//
//  BHDownloadInlineButton.m
//  NeoFreeBird
//
//  Original author: BandarHelal at 09/04/2022
//  Modified by: actuallyaridan at 27/04/2025
//

#import "Download/BHDownloadInlineButton.h"
#import <objc/runtime.h>
#import "Core/BHTBundle.h"
#import "Core/BHTSettings.h"

#pragma mark - Helpers
static UIWindow *BHTKeyWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static UIViewController *BHTopMostController(void) {
    UIViewController *top = BHTKeyWindow().rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    return top;
}

#pragma mark - BHDownloadInlineButton
@interface BHDownloadInlineButton () <BHDownloadDelegate>
@property (nonatomic, strong) JGProgressHUD *hud;
@end

@implementation BHDownloadInlineButton

#pragma mark - Download handler
- (void)presentDownloadOptionsForMediaEntities:(NSArray *)mediaEntities {
    @try {
        NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_MENU_TITLE"]
                                                                         attributes:@{ NSFontAttributeName : [BHTManager menuTitleFont],
                                                                                       NSForegroundColorAttributeName : UIColor.labelColor }];
        TFNActiveTextItem *title = [[objc_getClass("TFNActiveTextItem") alloc] initWithTextModel:[[objc_getClass("TFNAttributedTextModel") alloc] initWithAttributedString:titleString] activeRanges:nil];

        // HUD helpers
        void (^startHUD)(NSString *) = ^(NSString *text) {
            if ([BHTSettings boolForKey:@"direct_save"]) return;
            self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            self.hud.textLabel.text = text;
            [self.hud showInView:BHTopMostController().view];
        };
        void (^dismissHUD)(void) = ^{ [self.hud dismiss]; };

        // Variant builders
        TFNActionItem* (^makeMP4Item)(NSURL *) = ^TFNActionItem*(NSURL *url) {
            return [objc_getClass("TFNActionItem") actionItemWithTitle:[BHTManager getVideoQuality:url.absoluteString]
                                                               imageName:@"arrow_down_circle_stroke" action:^{
                BHDownload *dwManager = [[BHDownload alloc] init];
                [dwManager setDelegate:self];
                [dwManager downloadFileWithURL:url];
                startHUD([[BHTBundle sharedBundle] localizedTwitterStringForKey:@"DOWNLOAD_LIVE_ACTIVITY_DOWNLOADING"]);
            }];
        };

        TFNActionItem* (^makeM3U8Item)(NSURL *) = ^TFNActionItem*(NSURL *url) {
            return [objc_getClass("TFNActionItem") actionItemWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"FFMPEG_DOWNLOAD_OPTION_TITLE"]
                                                               imageName:@"arrow_down_circle_stroke" action:^{
                startHUD([[BHTBundle sharedBundle] localizedStringForKey:@"FETCHING_PROGRESS_TITLE"]);
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                    MediaInformation *info = [BHTManager getM3U8Information:url];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        dismissHUD();
                        TFNMenuSheetViewController *sheet = [BHTManager newFFmpegDownloadSheet:info downloadingURL:url progressView:self.hud];
                        [sheet tfnPresentedCustomPresentFromViewController:BHTopMostController() animated:YES completion:nil];
                    });
                });
            }];
        };

        // videoInfo.variants backs both video (mediaType 3) and GIF (mediaType 2);
        // photos carry no videoInfo.
        void (^appendVariants)(NSMutableArray *, TFSTwitterEntityMedia *) = ^(NSMutableArray *dest, TFSTwitterEntityMedia *media) {
            for (TFSTwitterEntityMediaVideoVariant *variant in media.videoInfo.variants) {
                NSURL *url = variant.url.length ? [NSURL URLWithString:variant.url] : nil;
                if (!url) continue;

                if ([variant.contentType isEqualToString:@"video/mp4"])                 [dest addObject:makeMP4Item(url)];
                else if ([variant.contentType isEqualToString:@"application/x-mpegURL"]) [dest addObject:makeM3U8Item(url)];
            }
        };

        // Filter to video/GIF so grouping keys off the real video count, not the raw media count.
        NSMutableArray<TFSTwitterEntityMedia *> *videoEntities = [NSMutableArray new];
        for (TFSTwitterEntityMedia *media in mediaEntities) {
            if ((media.mediaType == 2 || media.mediaType == 3) && media.videoInfo.variants.count > 0) {
                [videoEntities addObject:media];
            }
        }

        NSMutableArray *actions = [NSMutableArray arrayWithObject:title];

        if (videoEntities.count > 1) {
            [videoEntities enumerateObjectsUsingBlock:^(TFSTwitterEntityMedia *media, NSUInteger idx, BOOL *stop) {
                TFNActionItem *videoGroup = [objc_getClass("TFNActionItem") actionItemWithTitle:[NSString stringWithFormat:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_VIDEO_NUMBER_TITLE"], (unsigned long)idx + 1]
                                                                                   imageName:@"arrow_down_circle_stroke" action:^{
                    NSMutableArray *innerActions = [NSMutableArray arrayWithObject:title];
                    appendVariants(innerActions, media);

                    TFNMenuSheetViewController *inner = [[objc_getClass("TFNMenuSheetViewController") alloc] initWithActionItems:innerActions.copy];
                    [inner tfnPresentedCustomPresentFromViewController:BHTopMostController() animated:YES completion:nil];
                }];
                [actions addObject:videoGroup];
            }];
        } else {
            appendVariants(actions, videoEntities.firstObject);
        }

        TFNMenuSheetViewController *sheet = [[objc_getClass("TFNMenuSheetViewController") alloc] initWithActionItems:actions.copy];
        [sheet tfnPresentedCustomPresentFromViewController:BHTopMostController() animated:YES completion:nil];
    } @catch (__unused NSException *ex) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"ERROR_ALERT_TITLE"]
                                                                       message:[[BHTBundle sharedBundle] localizedStringForKey:@"UNKNOWN_ERROR"]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"OK_ACTION_LABEL"] style:UIAlertActionStyleDefault handler:nil]];
        [BHTopMostController() presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - BHDownloadDelegate
- (void)downloadProgress:(float)pct {
    self.hud.detailTextLabel.text = [BHTManager getDownloadingPersent:pct];
}

- (void)downloadDidFinish:(NSURL *)tmpURL Filename:(NSString *)name {
    NSString *doc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *dst = [[NSURL fileURLWithPath:doc]
                  URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", NSUUID.UUID.UUIDString]];

    NSError *moveError = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:tmpURL toURL:dst error:&moveError]) {
        [self downloadDidFailureWithError:moveError];
        return;
    }

    if (![BHTSettings boolForKey:@"direct_save"]) {
        [self.hud dismiss];
        [BHTManager showSaveVC:dst];
    } else {
        if (@available(iOS 10.0, *)) {
            UINotificationFeedbackGenerator *g = [UINotificationFeedbackGenerator new];
            [g prepare];
            [g notificationOccurred:UINotificationFeedbackTypeSuccess];
        }
        [BHTManager save:dst];
    }
}

- (void)downloadDidFailureWithError:(NSError *)error {
    [self.hud dismiss];
    if (!error) return;

    UIAlertController *a = [UIAlertController alertControllerWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"ERROR_ALERT_TITLE"]
                                                               message:error.localizedDescription
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"OK_ACTION_LABEL"]
                                          style:UIAlertActionStyleDefault
                                        handler:nil]];
    [BHTopMostController() presentViewController:a animated:YES completion:nil];

    if (@available(iOS 10.0, *)) {
        UINotificationFeedbackGenerator *g = [UINotificationFeedbackGenerator new];
        [g prepare];
        [g notificationOccurred:UINotificationFeedbackTypeError];
    }
}

@end
