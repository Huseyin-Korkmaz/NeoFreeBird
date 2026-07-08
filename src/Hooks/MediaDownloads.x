//
//  MediaDownloads.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: DM download
%hook T1DirectMessageEntryMediaCell
%property (nonatomic, strong) JGProgressHUD *hud;
- (void)setEntryViewModel:(id)arg1 {
    %orig;
    if ([BHTManager DownloadingVideos]) {
        UIContextMenuInteraction *menuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self setUserInteractionEnabled:true];

        if ([BHTManager isDMVideoCell:self.inlineMediaView]) {
            [self addInteraction:menuInteraction];
        }
    }
}
%new - (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *saveAction = [UIAction actionWithTitle:@"Download" image:[UIImage systemImageNamed:@"square.and.arrow.down"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [self DownloadHandler];
        }];
        return [UIMenu menuWithTitle:@"" children:@[saveAction]];
    }];
}
%new - (void)DownloadHandler {
    NSAttributedString *AttString = [[NSAttributedString alloc] initWithString:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_MENU_TITLE"] attributes:@{
        NSFontAttributeName: [BHTManager menuTitleFont],
        NSForegroundColorAttributeName: UIColor.labelColor
    }];
    TFNActiveTextItem *title = [[%c(TFNActiveTextItem) alloc] initWithTextModel:[[%c(TFNAttributedTextModel) alloc] initWithAttributedString:AttString] activeRanges:nil];

    NSMutableArray *actions = [[NSMutableArray alloc] init];
    [actions addObject:title];

    T1PlayerMediaEntitySessionProducible *session = self.inlineMediaView.viewModel.playerSessionProducer.sessionProducible;
    for (TFSTwitterEntityMediaVideoVariant *i in session.mediaEntity.videoInfo.variants) {
        if ([i.contentType isEqualToString:@"video/mp4"]) {
            TFNActionItem *download = [%c(TFNActionItem) actionItemWithTitle:[BHTManager getVideoQuality:i.url] imageName:@"arrow_down_circle_stroke" action:^{
                BHDownload *DownloadManager = [[BHDownload alloc] init];
                self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                self.hud.textLabel.text = [[BHTBundle sharedBundle] localizedStringForKey:@"PROGRESS_DOWNLOADING_STATUS_TITLE"];
                [DownloadManager downloadFileWithURL:[NSURL URLWithString:i.url]];
                [DownloadManager setDelegate:self];
                [self.hud showInView:topMostController().view];
            }];
            [actions addObject:download];
        }

        if ([i.contentType isEqualToString:@"application/x-mpegURL"]) {
            TFNActionItem *option = [objc_getClass("TFNActionItem") actionItemWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"FFMPEG_DOWNLOAD_OPTION_TITLE"] imageName:@"arrow_down_circle_stroke" action:^{

                self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                self.hud.textLabel.text = [[BHTBundle sharedBundle] localizedStringForKey:@"FETCHING_PROGRESS_TITLE"];
                [self.hud showInView:topMostController().view];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    MediaInformation *mediaInfo = [BHTManager getM3U8Information:[NSURL URLWithString:i.url]];
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self.hud dismiss];

                        TFNMenuSheetViewController *alert2 = [BHTManager newFFmpegDownloadSheet:mediaInfo downloadingURL:[NSURL URLWithString:i.url] progressView:self.hud];
                        [alert2 tfnPresentedCustomPresentFromViewController:topMostController() animated:YES completion:nil];
                    });
                });

            }];

            [actions addObject:option];
        }
    }

    TFNMenuSheetViewController *alert = [[%c(TFNMenuSheetViewController) alloc] initWithActionItems:[NSArray arrayWithArray:actions]];
    [alert tfnPresentedCustomPresentFromViewController:topMostController() animated:YES completion:nil];
}
%new - (void)downloadProgress:(float)progress {
    self.hud.detailTextLabel.text = [BHTManager getDownloadingPersent:progress];
}

%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *DocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *newFilePath = [[NSURL fileURLWithPath:DocPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", NSUUID.UUID.UUIDString]];
    [manager moveItemAtURL:filePath toURL:newFilePath error:nil];
    [self.hud dismiss];
    [BHTManager showSaveVC:newFilePath];
}
%new - (void)downloadDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}
%end

// upload custom voice
%hook T1MediaAttachmentsViewCell
%property (nonatomic, strong) UIButton *uploadButton;
- (void)updateCellElements {
    %orig;

    if ([BHTManager customVoice]) {
        TFNButton *removeButton = [self valueForKey:@"_removeButton"];

        if ([self.attachment isKindOfClass:%c(TTMAssetVoiceRecording)]) {
            if (self.uploadButton == nil) {
                self.uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
                UIImageSymbolConfiguration *smallConfig = [UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleSmall];
                UIImage *arrowUpImage = [UIImage systemImageNamed:@"arrow.up" withConfiguration:smallConfig];
                [self.uploadButton setImage:arrowUpImage forState:UIControlStateNormal];
                [self.uploadButton addTarget:self action:@selector(handleUploadButton:) forControlEvents:UIControlEventTouchUpInside];
                [self.uploadButton setTintColor:UIColor.labelColor];
                [self.uploadButton setBackgroundColor:[UIColor blackColor]];
                [self.uploadButton.layer setCornerRadius:29/2];
                [self.uploadButton setTranslatesAutoresizingMaskIntoConstraints:false];

                if (self.uploadButton.superview == nil) {
                    [self addSubview:self.uploadButton];
                    [NSLayoutConstraint activateConstraints:@[
                        [self.uploadButton.trailingAnchor constraintEqualToAnchor:removeButton.leadingAnchor constant:-10],
                        [self.uploadButton.topAnchor constraintEqualToAnchor:removeButton.topAnchor],
                        [self.uploadButton.widthAnchor constraintEqualToConstant:29],
                        [self.uploadButton.heightAnchor constraintEqualToConstant:29],
                    ]];
                }
            }
        }
    }
}
%new - (void)handleUploadButton:(UIButton *)sender {
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
    videoPicker.delegate = self;

    [topMostController() presentViewController:videoPicker animated:YES completion:nil];
}
%new - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    TTMAssetVoiceRecording *attachment = self.attachment;
    NSURL *recorder_url = [NSURL fileURLWithPath:attachment.filePath];

    if (recorder_url != nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSError *error = nil;
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
%new - (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:true completion:nil];
}
%end
// MARK: Save tweet as an image

%hook TTAStatusInlineShareButton
- (void)didLongPressActionButton:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([BHTManager tweetToImage]) {
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            id delegate = self.delegate;
            if (![delegate isKindOfClass:%c(TTAStatusInlineActionsView)]) {
                return %orig;
            }
            TTAStatusInlineActionsView *actionsView = (TTAStatusInlineActionsView *)delegate;
            T1StatusCell *tweetView;

            if ([actionsView.superview isKindOfClass:%c(T1StandardStatusView)]) { // normal tweet in the time line
                tweetView = (T1StatusCell *)[(T1StandardStatusView *)actionsView.superview eventHandler];
            } else if ([actionsView.superview isKindOfClass:%c(T1TweetDetailsFocalStatusView)]) { // Focus tweet
                tweetView = (T1StatusCell *)[(T1TweetDetailsFocalStatusView *)actionsView.superview eventHandler];
            } else if ([actionsView.superview isKindOfClass:%c(T1ConversationFocalStatusView)]) { // Focus tweet
                tweetView = (T1StatusCell *)[(T1ConversationFocalStatusView *)actionsView.superview eventHandler];
            } else {
                return %orig;
            }

            UIImage *tweetImage = BH_imageFromView(tweetView);
            NSData *pngData = UIImagePNGRepresentation(tweetImage);
            NSURL *pngURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]]];
            [pngData writeToURL:pngURL atomically:YES];
            UIActivityViewController *acVC = [[UIActivityViewController alloc] initWithActivityItems:@[pngURL] applicationActivities:nil];
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
// MARK: Timeline download

static NSArray *BHT_inlineActionViewClassesForViewModel(NSArray *classes, id viewModel) {
    if (![classes isKindOfClass:NSArray.class]) {
        return classes;
    }

    NSMutableArray *newClasses = [classes mutableCopy];

    Class analyticsButtonClass = %c(TTAStatusInlineAnalyticsButton);
    if (analyticsButtonClass &&
        [newClasses containsObject:analyticsButtonClass] &&
        [BHTManager hideViewCount]) {
        [newClasses removeObject:analyticsButtonClass];
    }

    Class bookmarkButtonClass = %c(TTAStatusInlineBookmarkButton);
    if (bookmarkButtonClass &&
        [newClasses containsObject:bookmarkButtonClass] &&
        [BHTManager hideBookmarkButton]) {
        [newClasses removeObject:bookmarkButtonClass];
    }

    Class downvoteButtonClass = %c(TTAStatusInlineDownvoteButton);
    if (downvoteButtonClass &&
        [newClasses containsObject:downvoteButtonClass] &&
        [BHTManager hideDownvoteButton]) {
        [newClasses removeObject:downvoteButtonClass];
    }

    return [newClasses copy];
}

%hook T1StatusInlineActionsView
+ (NSArray *)_t1_inlineActionViewClassesForViewModel:(id)arg1 options:(NSUInteger)arg2 displayType:(NSUInteger)arg3 account:(id)arg4 {
    NSArray *origClasses = %orig;
    return BHT_inlineActionViewClassesForViewModel(origClasses, arg1);
}
%end

%hook TTAStatusInlineActionsView
+ (NSArray *)_t1_inlineActionViewClassesForViewModel:(id)arg1 options:(NSUInteger)arg2 displayType:(NSUInteger)arg3 account:(id)arg4 {
    NSArray *origClasses = %orig;
    return BHT_inlineActionViewClassesForViewModel(origClasses, arg1);
}
// The downvote (dislike) button shown on replies/comments is gated by this
// method rather than being unconditionally present in the class list above.
// The array filter alone misses it, so intercept the gate directly: forcing
// NO prevents the button being built in every context (timeline and comments).
+ (BOOL)t1_shouldShowDownvoteButtonForViewModel:(id)arg1 options:(NSUInteger)arg2 anatomyFeatures:(id)arg3 displayType:(NSUInteger)arg4 account:(id)arg5 {
    if ([BHTManager hideDownvoteButton]) {
        return NO;
    }
    return %orig;
}
%end

// The reply/comment downvote button is created unconditionally and its actual
// display is driven by -visibility: the actions view lays out only buttons whose
// visibility is non-zero and calls setHidden:YES on the rest. Filtering the class
// list doesn't remove it from the hierarchy, so force its visibility to 0 — this
// excludes it from layout (no gap) and gets it hidden like any collapsed action.
%hook TTAStatusInlineDownvoteButton
- (NSUInteger)visibility {
    if ([BHTManager hideDownvoteButton]) {
        return 0;
    }
    return %orig;
}
%end

// Add a "Download media" item to the tweet overflow (3-dot) menu
%hook UIViewController
- (NSArray *)_t1_actionItemsForStatus:(__unsafe_unretained id)status account:(__unsafe_unretained id)account shareableEntity:(__unsafe_unretained id)shareableEntity entityURL:(__unsafe_unretained id)entityURL source:(__unsafe_unretained id)source options:(NSUInteger)options scribeComponent:(__unsafe_unretained id)scribeComponent doneBlock:(__unsafe_unretained id)doneBlock {
    NSArray *origItems = %orig;

    if (![BHTManager DownloadingVideos] || ![status respondsToSelector:@selector(entities)]) {
        return origItems;
    }

    NSArray *mediaEntities = [[status entities] media];
    BOOL hasVideo = NO;
    for (TFSTwitterEntityMedia *media in mediaEntities) {
        if ([media isKindOfClass:%c(TFSTwitterEntityMedia)] && (media.mediaType == 2 || media.mediaType == 3)) {
            hasVideo = YES;
            break;
        }
    }
    if (!hasVideo) {
        return origItems;
    }

    static char downloaderKey;
    BHDownloadInlineButton *downloader = objc_getAssociatedObject(self, &downloaderKey);
    if (!downloader) {
        downloader = [%c(BHDownloadInlineButton) new];
        objc_setAssociatedObject(self, &downloaderKey, downloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    TFNActionItem *downloadItem = [%c(TFNActionItem) actionItemWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"DOWNLOAD_VIDEOS_OPTION_TITLE"]
                                                              imageName:@"arrow_down_circle_stroke" action:^{
        [downloader presentDownloadOptionsForMediaEntities:mediaEntities];
    }];

    NSMutableArray *newItems = origItems ? [origItems mutableCopy] : [NSMutableArray array];
    NSUInteger insertIndex = newItems.count > 0 ? newItems.count - 1 : 0;
    [newItems insertObject:downloadItem atIndex:insertIndex];
    return newItems;
}
%end
