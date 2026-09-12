//
//  MediaDownloads.x
//  NeoFreeBird
//

#import "HookHelpers.h"
#import <objc/runtime.h>

@interface T1MediaContextMenu : NSObject
- (id)mediaEntity;
- (id)media;
@end

static NSURL* nfbLastCapturedVoiceURL = nil;

static BOOL IsVoiceMediaURL(NSURL* url) {
    if (url == nil) {
        return NO;
    }
    if ([url.path containsString:@"/decrypted-media-v2/"]) {
        return YES;
    }
    static NSSet* audioExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioExtensions = [NSSet setWithArray:@[@"m4a", @"aac", @"caf", @"wav", @"mp3"]];
    });
    return [audioExtensions containsObject:url.pathExtension.lowercaseString];
}

static void CaptureVoiceURL(NSURL* url, NSString* source) {
    if (![BHTSettings boolForKey:@"download_voice_messages"]) {
        return;
    }
    BOOL kept = IsVoiceMediaURL(url);
    NSLog(@"[NFB] voice capture (%@) %@: %@", source, kept ? @"kept" : @"ignored", url);
    if (kept) {
        nfbLastCapturedVoiceURL = url;
    }
}

%hook AVURLAsset
- (id)initWithURL:(NSURL*)url options:(NSDictionary*)options {
    CaptureVoiceURL(url, @"AVURLAsset");
    return %orig;
}
%end

// AVAudioPlayer is covered as well as AVURLAsset because the Chat stack no
// longer has to build an AVPlayer to play a short local note.
%hook AVAudioPlayer
- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)outError {
    CaptureVoiceURL(url, @"AVAudioPlayer");
    return %orig;
}
- (id)initWithContentsOfURL:(NSURL*)url
               fileTypeHint:(NSString*)utiString
                      error:(NSError**)outError {
    CaptureVoiceURL(url, @"AVAudioPlayer/fileTypeHint");
    return %orig;
}
%end

// DM voice notes are pre-decrypted straight to disk (Documents/dm/.../
// decrypted-media-v2/.../*.m4a), so the captured URL is normally a local
// file URL already -- just copy it out and hand it to the share sheet. The
// network branch is kept as a fallback in case that ever changes.
static void DownloadVoiceMessage(NSURL* sourceURL) {
    NSString* extension = sourceURL.pathExtension.length ? sourceURL.pathExtension : @"m4a";
    NSURL* destination = [[NSURL fileURLWithPath:NSTemporaryDirectory()]
        URLByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, extension]];

    if (sourceURL.isFileURL) {
        NSError* copyError = nil;
        [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destination error:&copyError];
        if (copyError) {
            NSLog(@"[NFB] DownloadVoiceMessage copy failed: %@", copyError);
            return;
        }
        [BHTManager showSaveVC:destination];
        return;
    }

    TFNHUD* hud = [[objc_getClass("TFNHUD") alloc]
        initWithText:[[BHTBundle sharedBundle]
                          localizedStringForKey:@"DOWNLOAD_LIVE_ACTIVITY_DOWNLOADING"]];
    [hud show];
    NSURLSessionDownloadTask* task = [[NSURLSession sharedSession]
        downloadTaskWithURL:sourceURL
          completionHandler:^(NSURL* location, NSURLResponse* response, NSError* error) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [hud hide];
                  if (!location || error) {
                      return;
                  }
                  NSError* moveError = nil;
                  [[NSFileManager defaultManager] moveItemAtURL:location toURL:destination error:&moveError];
                  if (moveError) {
                      return;
                  }
                  [BHTManager showSaveVC:destination];
              });
          }];
    [task resume];
}

// MARK: - DM video download

// The DM UI is Swift now: media messages live in DMConversation.MessageAttachmentView,
// which hosts a shared TweetMediaAttachments media view exposing its models through
// -inlineMediaInfos. Collect the entities from whichever descendant carries them.
static NSArray* DMVideoEntities(UIView* attachmentView) {
    NSMutableArray* entities = [NSMutableArray new];

    EnumerateSubviewsRecursively(attachmentView, ^(UIView* view) {
        if (![view respondsToSelector:@selector(inlineMediaInfos)]) {
            return;
        }

        for (TFSTwitterMediaInfo* info in
             [(_TtC21TweetMediaAttachments14MultiMediaView*)view inlineMediaInfos]) {
            TFSTwitterEntityMedia* media = info.mediaEntity;
            if (media.videoInfo.variants.count > 0) {
                [entities addObject:media];
            }
        }
    });

    return [entities copy];
}

%hook _TtC14DMConversation21MessageAttachmentView
%property (nonatomic, strong) UIContextMenuInteraction* downloadMenuInteraction;
%property (nonatomic, strong) DownloadInlineButton* downloadHandler;
- (void)layoutSubviews {
    %orig;

    if ([BHTSettings boolForKey:@"download_videos"] && self.downloadMenuInteraction == nil) {
        self.downloadMenuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:self.downloadMenuInteraction];
    }
}
%new
- (UIContextMenuConfiguration*)contextMenuInteraction:(UIContextMenuInteraction*)interaction
                       configurationForMenuAtLocation:(CGPoint)location {
    NSArray* videoEntities = DMVideoEntities(self);
    if (videoEntities.count == 0) {
        return nil;
    }

    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu* _Nullable(
                         NSArray<UIMenuElement*>* _Nonnull suggestedActions) {
                         UIAction* saveAction = [UIAction
                             actionWithTitle:
                                 [[BHTBundle sharedBundle]
                                     localizedTwitterStringForKey:@"DOWNLOAD_ACTIVITY_VIEW_LABEL"]
                                       image:[UIImage systemImageNamed:@"square.and.arrow.down"]
                                  identifier:nil
                                     handler:^(__kindof UIAction* _Nonnull action) {
                                         if (self.downloadHandler == nil) {
                                             self.downloadHandler = [%c(DownloadInlineButton) new];
                                         }
                                         [self.downloadHandler
                                             presentDownloadOptionsForMediaEntities:videoEntities];
                                     }];
                         return [UIMenu menuWithTitle:@"" children:@[saveAction]];
                     }];
}
%end


// MARK: - Chat voice bubble

static const void* kVoiceDownloadLongPressKey = &kVoiceDownloadLongPressKey;

static UILongPressGestureRecognizer* VoiceDownloadLongPressRecognizer(UIView* view) {
    return objc_getAssociatedObject(view, kVoiceDownloadLongPressKey);
}

static void SetVoiceDownloadLongPressRecognizer(UIView* view,
                                                UILongPressGestureRecognizer* recognizer) {
    objc_setAssociatedObject(view, kVoiceDownloadLongPressKey, recognizer,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%hook _TtC16ChatConversation26MessageAttachmentAudioView

- (void)layoutSubviews {
    %orig;

    if (![BHTSettings boolForKey:@"download_voice_messages"] ||
        VoiceDownloadLongPressRecognizer(self) != nil) {
        return;
    }

    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(nfb_handleVoiceDownloadLongPress:)];
    longPress.minimumPressDuration = 0.5;
    longPress.numberOfTouchesRequired = 2;
    longPress.cancelsTouchesInView = NO;

    [self addGestureRecognizer:longPress];
    SetVoiceDownloadLongPressRecognizer(self, longPress);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer == VoiceDownloadLongPressRecognizer(self)) {
        return YES;
    }
    return %orig;
}

%new
- (void)nfb_handleVoiceDownloadLongPress:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }

    NSURL* voiceURL = nfbLastCapturedVoiceURL;
    if (voiceURL == nil) {
        return;
    }

    TFNActionItem* downloadItem = [objc_getClass("TFNActionItem")
        actionItemWithTitle:[[BHTBundle sharedBundle]
                                localizedStringForKey:@"DOWNLOAD_ACTIVITY_VIEW_LABEL"]
                  imageName:@"arrow_down_circle_stroke"
                     action:^{
                         DownloadVoiceMessage(voiceURL);
                     }];

    TFNMenuSheetViewController* sheet = [[objc_getClass("TFNMenuSheetViewController") alloc]
        initWithActionItems:@[downloadItem]];

    [sheet tfnPresentedCustomPresentFromViewController:topMostController()
                                              animated:YES
                                            completion:nil];
}

%end

// MARK: - Upload custom voice

%hook T1MediaAttachmentsViewCell
%property (nonatomic, strong) UIButton* uploadButton;
- (void)updateCellElements {
    %orig;

    BOOL isVoiceRecording = [self.attachment isKindOfClass:%c(TTMAssetVoiceRecording)];

    if (isVoiceRecording && self.uploadButton == nil) {
        TFNButton* removeButton = [self valueForKey:@"_removeButton"];
        if (removeButton == nil) {
            return;
        }

        self.uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImageSymbolConfiguration* smallConfig =
            [UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleSmall];
        UIImage* arrowUpImage = [UIImage systemImageNamed:@"arrow.up" withConfiguration:smallConfig];
        [self.uploadButton setImage:arrowUpImage forState:UIControlStateNormal];
        [self.uploadButton addTarget:self
                              action:@selector(handleUploadButton:)
                    forControlEvents:UIControlEventTouchUpInside];
        [self.uploadButton setTintColor:UIColor.labelColor];
        [self.uploadButton setBackgroundColor:[UIColor blackColor]];
        [self.uploadButton.layer setCornerRadius:29 / 2];
        [self.uploadButton setTranslatesAutoresizingMaskIntoConstraints:false];

        [self addSubview:self.uploadButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.uploadButton.trailingAnchor constraintEqualToAnchor:removeButton.leadingAnchor
                                                             constant:-10],
            [self.uploadButton.topAnchor constraintEqualToAnchor:removeButton.topAnchor],
            [self.uploadButton.widthAnchor constraintEqualToConstant:29],
            [self.uploadButton.heightAnchor constraintEqualToConstant:29],
        ]];
    }

    self.uploadButton.hidden = !isVoiceRecording;
}
%new
- (void)handleUploadButton:(UIButton*)sender {
    UIImagePickerController* videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
    videoPicker.delegate = self;

    [topMostController() presentViewController:videoPicker animated:YES completion:nil];
}
%new
- (void)imagePickerController:(UIImagePickerController*)picker
    didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id>*)info {
    NSURL* videoURL = info[UIImagePickerControllerMediaURL];
    TTMAssetVoiceRecording* attachment = self.attachment;
    NSURL* recorder_url = [NSURL fileURLWithPath:attachment.filePath];

    if (recorder_url != nil) {
        NSFileManager* fileManager = [NSFileManager defaultManager];

        NSError* error = nil;
        if ([fileManager fileExistsAtPath:[recorder_url path]]) {
            [fileManager removeItemAtURL:recorder_url error:&error];
            if (error) {
                NSLog(@"[BHTwitter] Error removing existing file: %@", error);
            }
        }

        [fileManager copyItemAtURL:videoURL toURL:recorder_url error:&error];
        if (error) {
            NSLog(@"[BHTwitter] Error copying file: %@", error);
        }
    }

    [picker dismissViewControllerAnimated:true completion:nil];
}
%new
- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    [picker dismissViewControllerAnimated:true completion:nil];
}
%end

// MARK: - Save tweet as an image

%hook TTAStatusInlineShareButton
- (void)didLongPressActionButton:(UILongPressGestureRecognizer*)gestureRecognizer {
    if ([BHTSettings boolForKey:@"tweet_to_image"]) {
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            UIView* statusView = self.superview;
            while (statusView && ![statusView respondsToSelector:@selector(eventHandler)]) {
                statusView = statusView.superview;
            }

            UIView* tweetView = nil;
            id eventHandler = [(T1StandardStatusView*)statusView eventHandler];
            if ([eventHandler isKindOfClass:UIView.class]) {
                tweetView = eventHandler;
            }

            if (tweetView == nil) {
                UIView* ancestor = self.superview;
                while (ancestor && ![ancestor isKindOfClass:UITableViewCell.class] &&
                       ![ancestor isKindOfClass:UICollectionViewCell.class]) {
                    ancestor = ancestor.superview;
                }
                tweetView = ancestor;
            }

            if (tweetView == nil) {
                return %orig;
            }

            UIImage* tweetImage = imageFromView(tweetView);
            NSData* pngData = UIImagePNGRepresentation(tweetImage);
            NSURL* pngURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()]
                URLByAppendingPathComponent:[NSString
                                                stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]]];
            [pngData writeToURL:pngURL atomically:YES];
            UIActivityViewController* acVC =
                [[UIActivityViewController alloc] initWithActivityItems:@[pngURL]
                                                  applicationActivities:nil];
            if (is_iPad()) {
                acVC.popoverPresentationController.sourceView = self;
                acVC.popoverPresentationController.sourceRect = self.frame;
            }
            [topMostController() presentViewController:acVC animated:true completion:nil];
            return;
        }
    }
    return %orig;
}
%end

// MARK: - Tweet video download (Share Sheet & Context Menu)

%hook UIViewController
- (NSArray*)_t1_actionItemsForStatus:(__unsafe_unretained id)status
                             account:(__unsafe_unretained id)account
                     shareableEntity:(__unsafe_unretained id)shareableEntity
                           entityURL:(__unsafe_unretained id)entityURL
                              source:(__unsafe_unretained id)source
                             options:(NSUInteger)options
                     scribeComponent:(__unsafe_unretained id)scribeComponent
                           doneBlock:(__unsafe_unretained id)doneBlock {
    NSArray* origItems = %orig;

    if (![BHTSettings boolForKey:@"download_videos"] ||
        ![status respondsToSelector:@selector(entities)]) {
        return origItems;
    }

    NSArray* mediaEntities = [[status entities] media];
    BOOL hasVideo = NO;
    for (TFSTwitterEntityMedia* media in mediaEntities) {
        if ([media isKindOfClass:%c(TFSTwitterEntityMedia)] &&
            media.videoInfo && media.videoInfo.variants.count > 0) {
            hasVideo = YES;
            break;
        }
    }
    if (!hasVideo) {
        return origItems;
    }

    static char downloaderKey;
    DownloadInlineButton* downloader = objc_getAssociatedObject(self, &downloaderKey);
    if (!downloader) {
        downloader = [%c(DownloadInlineButton) new];
        objc_setAssociatedObject(self, &downloaderKey, downloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    TFNActionItem* downloadItem = [%c(TFNActionItem)
        actionItemWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_VIDEOS_TITLE"]
                  imageName:@"arrow_down_circle_stroke"
                     action:^{
                         [downloader presentDownloadOptionsForMediaEntities:mediaEntities];
                     }];

    NSMutableArray* newItems = origItems ? [origItems mutableCopy] : [NSMutableArray array];
    NSUInteger insertIndex = newItems.count > 0 ? newItems.count - 1 : 0;
    [newItems insertObject:downloadItem atIndex:insertIndex];
    return newItems;
}
%end

// MARK: - Force Inject Download Option into Status Action Controller

%hook T1StatusActionController
- (id)actionItemsForStatus:(id)status options:(NSUInteger)options {
    id origResult = %orig(status, options);
    NSMutableArray *items = [origResult mutableCopy];
    if (!items) {
        items = [NSMutableArray array];
    }

    if (![BHTSettings boolForKey:@"download_videos"]) {
        return items;
    }

    BOOL hasDownload = NO;
    for (id item in items) {
        if ([item respondsToSelector:@selector(title)] && 
            ([[item title] containsString:@"İndir"] || [[item title] containsString:@"Download"])) {
            hasDownload = YES;
            break;
        }
    }

    if (!hasDownload) {
        TFSTwitterEntityMedia *media = nil;
        if ([status respondsToSelector:@selector(entities)]) {
            NSArray *mediaEntities = [[status entities] media];
            for (TFSTwitterEntityMedia *m in mediaEntities) {
                if (m.videoInfo && m.videoInfo.variants.count > 0) {
                    media = m;
                    break;
                }
            }
        }

        if (media) {
            TFNActionItem *downloadItem = [%c(TFNActionItem)
                actionItemWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_VIDEOS_TITLE"]
                          imageName:@"arrow_down_circle_stroke"
                             action:^{
                                 DownloadInlineButton *downloader = [%c(DownloadInlineButton) new];
                                 [downloader presentDownloadOptionsForMediaEntities:@[media]];
                             }];
            
            NSUInteger index = items.count > 0 ? items.count - 1 : 0;
            [items insertObject:downloadItem atIndex:index];
        }
    }

    return items;
}
%end

// MARK: - Direct Video Long-Press Context Menu Hook (T1MediaContextMenu)

%hook T1MediaContextMenu
- (NSArray *)actionItems {
    NSArray *origItems = %orig;
    NSMutableArray *items = origItems ? [origItems mutableCopy] : [NSMutableArray array];

    if (![BHTSettings boolForKey:@"download_videos"]) {
        return items;
    }

    BOOL hasDownload = NO;
    for (id item in items) {
        if ([item respondsToSelector:@selector(title)] && 
            ([[item title] containsString:@"İndir"] || [[item title] containsString:@"Download"])) {
            hasDownload = YES;
            break;
        }
    }

    if (!hasDownload) {
        TFSTwitterEntityMedia *media = nil;
        if ([self respondsToSelector:@selector(mediaEntity)]) {
            media = [self mediaEntity];
        } else if ([self respondsToSelector:@selector(media)]) {
            media = [self media];
        }

        if (media) {
            TFNActionItem *downloadItem = [%c(TFNActionItem)
                actionItemWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_VIDEOS_TITLE"]
                          imageName:@"arrow_down_circle_stroke"
                             action:^{
                                 DownloadInlineButton *downloader = [%c(DownloadInlineButton) new];
                                 [downloader presentDownloadOptionsForMediaEntities:@[media]];
                             }];

            NSUInteger index = items.count > 0 ? items.count - 1 : 0;
            [items insertObject:downloadItem atIndex:index];
        }
    }

    return items;
}
%end
