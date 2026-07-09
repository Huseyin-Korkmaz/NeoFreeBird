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
+ (BOOL)doesContainDigitsOnly:(NSString *)string;
+ (UIViewController *)BHTSettingsWithAccount:(TFNTwitterAccount *)twAccount;
+ (void)showSaveVC:(NSURL *)url;
+ (void)save:(NSURL *)url;
+ (MediaInformation *)getM3U8Information:(NSURL *)mediaURL;
+ (TFNMenuSheetViewController *)newFFmpegDownloadSheet:(MediaInformation *)mediaInformation downloadingURL:(NSURL *)downloadingURL progressView:(JGProgressHUD *)hud;

+ (BOOL)isTwitterBranded;

@end
