//
//  BHTdownloadManager.m
//  BHTwitter
//
//  Created by BandarHelal.
//

#import "Core/BHTManager.h"
#import "Core/BHTSettings.h"
#import "Core/BHTBundle.h"
#import "Settings/ModernSettingsViewController.h"

@implementation BHTManager
+ (void)cleanCache {
    NSArray <NSURL *> *DocumentFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject] includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];

    for (NSURL *file in DocumentFiles) {
        if ([file.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
    }

    NSArray <NSURL *> *TempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory()] includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];

    for (NSURL *file in TempFiles) {
        if ([file.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
        if ([file.pathExtension.lowercaseString isEqualToString:@"mov"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
        if ([file.pathExtension.lowercaseString isEqualToString:@"tmp"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
        if ([file hasDirectoryPath]) {
            if ([BHTManager isEmpty:file]) {
                [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
            }
        }
    }
}
+ (BOOL)isEmpty:(NSURL *)url {
    NSArray *FolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    if (FolderFiles.count == 0) {
        return true;
    } else {
        return false;
    }
}
+ (NSString *)getDownloadingPersent:(float)per {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    NSNumber *number = [NSNumber numberWithFloat:per];
    return [numberFormatter stringFromNumber:number];
}
+ (id)sharedFontGroup {
    // TAEStandardFontGroup was renamed to TFNUIDefaultFontGroup in 12.3.
    return [objc_getClass("TFNUIDefaultFontGroup") sharedFontGroup];
}
+ (UIFont *)menuTitleFont {
    UIFont *font = [[self sharedFontGroup] headline2BoldFont];
    if (!font) font = [UIFont boldSystemFontOfSize:17.0];
    return font;
}
+ (NSString *)getVideoQuality:(NSString *)url {
    NSMutableArray *q = [NSMutableArray new];
    NSArray *splits = [url componentsSeparatedByString:@"/"];
    for (int i = 0; i < [splits count]; i++) {
        NSString *item = [splits objectAtIndex:i];
        NSArray *dir = [item componentsSeparatedByString:@"x"];
        for (int k = 0; k < [dir count]; k++) {
            NSString *item2 = [dir objectAtIndex:k];
            if (!(item2.length == 0)) {
                if ([BHTManager doesContainDigitsOnly:item2]) {
                    if (!(item2.integerValue > 10000)) {
                        if (!(q.count == 2)) {
                            [q addObject:item2];
                        }
                    }
                }
            }
        }
    }
    if (q.count == 0) {
        return @"GIF";
    }
    return [NSString stringWithFormat:@"%@x%@", q.firstObject, q.lastObject];
}
+ (void)save:(NSURL *)url {
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } error:nil];
}
+ (void)showSaveVC:(NSURL *)url {
    UIActivityViewController *acVC = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    if (is_iPad()) {
        acVC.popoverPresentationController.sourceView = topMostController().view;
        acVC.popoverPresentationController.sourceRect = CGRectMake(topMostController().view.bounds.size.width / 2.0, topMostController().view.bounds.size.height / 2.0, 1.0, 1.0);
    }
    [topMostController() presentViewController:acVC animated:true completion:nil];
}

+ (MediaInformation *)getM3U8Information:(NSURL *)mediaURL {
    MediaInformationSession *mediaInformationSession = [FFprobeKit getMediaInformation:mediaURL.absoluteString];
    MediaInformation *mediaInformation = [mediaInformationSession getMediaInformation];
    return mediaInformation;
}
+ (TFNMenuSheetViewController *)newFFmpegDownloadSheet:(MediaInformation *)mediaInformation downloadingURL:(NSURL *)downloadingURL progressView:(JGProgressHUD *)hud {
    NSAttributedString *AttString = [[NSAttributedString alloc] initWithString:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_MENU_TITLE"] attributes:@{
        NSFontAttributeName: [BHTManager menuTitleFont],
        NSForegroundColorAttributeName: UIColor.labelColor
    }];
    TFNActiveTextItem *title = [[objc_getClass("TFNActiveTextItem") alloc] initWithTextModel:[[objc_getClass("TFNAttributedTextModel") alloc] initWithAttributedString:AttString] activeRanges:nil];

    NSMutableArray *actions = [[NSMutableArray alloc] init];
    [actions addObject:title];

    for (StreamInformation *stream in [mediaInformation getStreams]) {
        NSNumber *width = [stream getWidth];
        NSNumber *height = [stream getHeight];
        if (width != nil && height != nil) {
            NSString *resolution = [NSString stringWithFormat:@"%@x%@", width, height];
            TFNActionItem *downloadOption = [objc_getClass("TFNActionItem") actionItemWithTitle:resolution imageName:@"arrow_down_circle_stroke" action:^{
                hud.textLabel.text = [[BHTBundle sharedBundle] localizedTwitterStringForKey:@"DOWNLOAD_LIVE_ACTIVITY_DOWNLOADING"];
                [hud showInView:topMostController().view];

                NSURL *newFilePath = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", NSUUID.UUID.UUIDString]];
                [FFmpegKit executeAsync:[NSString stringWithFormat:@"-i %@ -vf scale=%@:flags=lanczos -b:v 2M -c:a copy %@", downloadingURL.absoluteString, resolution, newFilePath.path] withCompleteCallback:^(FFmpegSession *session) {
                    ReturnCode *returnCode = [session getReturnCode];
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        if ([ReturnCode isSuccess:returnCode]) {
                            if (!([BHTSettings boolForKey:@"direct_save"])) {
                                [hud dismiss];
                                [BHTManager showSaveVC:newFilePath];
                            } else {
                                [BHTManager save:newFilePath];
                            }
                        } else {
                            [hud dismiss];
                        }
                    });
                }];
            }];
            [actions addObject:downloadOption];
        }
    }

    TFNMenuSheetViewController *alert = [[objc_getClass("TFNMenuSheetViewController") alloc] initWithActionItems:[NSArray arrayWithArray:actions]];
    return alert;
}

+ (BOOL)isTwitterBranded {
    static BOOL branded = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        branded = [[[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"] isEqual:@"Twitter"];
    });
    return branded;
}

+ (UIViewController *)BHTSettingsWithAccount:(TFNTwitterAccount *)twAccount {
    return [[ModernSettingsViewController alloc] initWithAccount:twAccount];
}

// https://stackoverflow.com/a/45356575/9910699
+ (BOOL)doesContainDigitsOnly:(NSString *)string {
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    BOOL containsDigitsOnly = [string rangeOfCharacterFromSet:nonDigits].location == NSNotFound;

    return containsDigitsOnly;
}

@end
