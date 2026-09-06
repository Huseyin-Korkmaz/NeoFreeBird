//
//  ImmersivePlayer.x
//  NeoFreeBird
//

#import "HookHelpers.h"

// MARK: - Immersive Player Timestamp

enum {
    CardStateFieldIsPanningBetweenCards = 19,
    CardStateFieldIsChromeFadedOutWhilePanning = 20,
};

static const uint8_t* immersiveCardStateMetadata(void) {
    static const uint8_t* metadata;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        const void* (*getType)(const char*, size_t, const void*,
                               const void* const*) =
            dlsym(RTLD_DEFAULT, "swift_getTypeByMangledNameInEnvironment");
        if (getType) {
            const char* mangledName = "14T1TwitterSwift18ImmersiveCardStateV";
            metadata = getType(mangledName, strlen(mangledName), NULL, NULL);
        }
    });
    return metadata;
}

static BOOL cardStateBoolField(const uint8_t* state,
                               uint32_t fieldIndex,
                               BOOL* outValue) {
    const uint8_t* metadata = immersiveCardStateMetadata();
    if (!metadata) {
        return NO;
    }

    const uint8_t* descriptor = *(const uint8_t* const*)(metadata + 8);
    uint32_t numFields = *(const uint32_t*)(descriptor + 20);
    uint32_t offsetVectorOffset = *(const uint32_t*)(descriptor + 24);
    if (fieldIndex >= numFields || offsetVectorOffset == 0) {
        return NO;
    }

    const int32_t* fieldOffsets =
        (const int32_t*)(metadata + offsetVectorOffset * sizeof(void*));
    *outValue = state[fieldOffsets[fieldIndex]] & 1;
    return YES;
}

static BOOL progressLabelAlphaFromState(id pluginView, CGFloat* outAlpha) {
    Ivar stateIvar = class_getInstanceVariable([pluginView class], "state");
    if (!stateIvar) {
        return NO;
    }

    uint8_t* state =
        (uint8_t*)(__bridge void*)pluginView + ivar_getOffset(stateIvar);
    uint64_t displayModeCase = *(uint64_t*)state;
    uint8_t displayModeTag = state[8];

    BOOL visible =
        displayModeTag == 1 && (displayModeCase < 1 || displayModeCase > 3);

    if (visible) {
        BOOL panning = NO, chromeFaded = NO;
        if (cardStateBoolField(state, CardStateFieldIsPanningBetweenCards,
                               &panning) &&
            panning) {
            visible = NO;
        } else if (cardStateBoolField(state,
                                      CardStateFieldIsChromeFadedOutWhilePanning,
                                      &chromeFaded) &&
                   chromeFaded) {
            visible = NO;
        }
    }

    *outAlpha = visible ? 1.0 : 0.0;
    return YES;
}

static const void* kBHTRestoredTimestampKey = &kBHTRestoredTimestampKey;

enum {
    ProgressLabelModeRemaining = 0,
    ProgressLabelModeTotal = 1,
};

%hook _TtC14T1TwitterSwift17VideoControlsView

- (void)layoutSubviews {
    %orig;

    BHTApplyDimToVideoControls(self);

    if (![BHTSettings boolForKey:@"restore_video_timestamp"] ||
        objc_getAssociatedObject(self, kBHTRestoredTimestampKey)) {
        return;
    }

    Ivar modeIvar =
        class_getInstanceVariable([self class], "progressLabelMode");
    if (!modeIvar) {
        return;
    }

    objc_setAssociatedObject(self, kBHTRestoredTimestampKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    uint8_t* mode = (uint8_t*)(__bridge void*)self + ivar_getOffset(modeIvar);
    *mode = ProgressLabelModeTotal;
}

%end

%hook _TtC14T1TwitterSwift24ImmersivePiPDropZoneView
- (void)didMoveToWindow {
    %orig;
    if ([BHTSettings boolForKey:@"disable_video_docking"]) {
        self.hidden = true;
        self.alpha = 0.0;
        self.userInteractionEnabled = false;
        for (UIView* subview in self.subviews) {
            subview.hidden = true;
            subview.alpha = 0.0;
            subview.userInteractionEnabled = false;
        }
    }
}

%end

%hook T1ImmersiveViewController

- (BOOL)isCurrentCardDockEligible {
    if ([BHTSettings boolForKey:@"disable_video_docking"]) {
        return NO;
    }

    return %orig;
}

%end

%hook T1ImmersiveViewControllerV2

- (BOOL)isCurrentCardDockEligible {
    if ([BHTSettings boolForKey:@"disable_video_docking"]) {
        return NO;
    }

    return %orig;
}

%end

// MARK: - Disable Immersive Feed Scrolling

static BOOL isImmersiveCardPan(id viewController,
                               UIGestureRecognizer* gesture) {
    Ivar panIvar =
        class_getInstanceVariable([viewController class], "panRecognizer");
    return panIvar && object_getIvar(viewController, panIvar) == gesture;
}

static BOOL isUpwardPan(UIGestureRecognizer *gesture) {
    if (![gesture isKindOfClass:[UIPanGestureRecognizer class]]) return NO;
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gesture;
    CGPoint v = [pan velocityInView:gesture.view];
    return v.y < 0.0;
}

%hook T1ImmersiveViewController

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if ([BHTSettings boolForKey:@"disable_immersive_scroll"] &&
        isImmersiveCardPan(self, gesture)) {
        if (isUpwardPan(gesture)) {
            return NO;
        }
        return YES;
    }

    return %orig;
}

- (BOOL)allowsUpwardSwipeToDismiss {
    if ([BHTSettings boolForKey:@"disable_immersive_scroll"]) {
        return NO;
    }

    return %orig;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if ([BHTSettings boolForKey:@"disable_immersive_scroll"]) {
        CGPoint v = [pan velocityInView:self.view];
        if (v.y < 0.0) {
            return;
        }
    }

    %orig(pan);
}

%end

%hook T1ImmersiveViewControllerV2

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if ([BHTSettings boolForKey:@"disable_immersive_scroll"] &&
        isImmersiveCardPan(self, gesture)) {
        if (isUpwardPan(gesture)) {
            return NO;
        }
        return YES;
    }

    return %orig;
}

- (BOOL)allowsUpwardSwipeToDismiss {
    if ([BHTSettings boolForKey:@"disable_immersive_scroll"]) {
        return NO;
    }

    return %orig;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if ([BHTSettings boolForKey:@"disable_immersive_scroll"]) {
        CGPoint v = [pan velocityInView:self.view];
        if (v.y < 0.0) {
            return;
        }
    }

    %orig(pan);
}

%end

// MARK: - Tap to Play/Pause & Long Press to Download

static TAVPlayer* immersivePagePlayer(UIView* pageView) {
    Ivar playerIvar = class_getInstanceVariable([pageView class], "player");
    return playerIvar ? object_getIvar(pageView, playerIvar) : nil;
}

static void togglePlayback(TAVPlayer* player) {
    if (player.playbackState.timeControlStatus != 0) {
        [player pause];
    } else {
        [player playOrReplay];
    }
}

static const void* kBHTTwoFingerTapKey = &kBHTTwoFingerTapKey;
static const void* kBHTLongPressDownloadKey = &kBHTLongPressDownloadKey;

%hook _TtC14T1TwitterSwift17ImmersiveCardView

- (void)didMoveToWindow {
    %orig;

    if (!self.window) {
        return;
    }

    // Çift Parmakla Durdurma
    if (!objc_getAssociatedObject(self, kBHTTwoFingerTapKey)) {
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(bht_handleTwoFingerTap:)];
        tap.numberOfTouchesRequired = 2;
        tap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tap];

        objc_setAssociatedObject(self, kBHTTwoFingerTapKey, tap,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // Basılı Tutarak İndirme (Long Press)
    if (!objc_getAssociatedObject(self, kBHTLongPressDownloadKey)) {
        UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(bht_handleLongPressDownload:)];
        longPress.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPress];

        objc_setAssociatedObject(self, kBHTLongPressDownloadKey, longPress,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (void)bht_handleTwoFingerTap:(UITapGestureRecognizer*)tap {
    if (![BHTSettings boolForKey:@"tap_to_pause"]) {
        return;
    }

    __block UIView* pageView = nil;
    EnumerateSubviewsRecursively(self, ^(UIView* view) {
        if (!pageView &&
            [view isKindOfClass:%c(_TtC14T1TwitterSwift22ImmersiveVideoPageView)]) {
            pageView = view;
        }
    });

    TAVPlayer* player = pageView ? immersivePagePlayer(pageView) : nil;
    if (!player) {
        return;
    }

    BOOL wasPlaying = player.playbackState.timeControlStatus != 0;
    togglePlayback(player);

    [self setPausedByUser:wasPlaying];
}

%new
- (void)bht_handleLongPressDownload:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan || ![BHTSettings boolForKey:@"download_videos"]) {
        return;
    }

    __block id mediaEntity = nil;
    
    // Kart içindeki media nesnesini bul
    Ivar viewModelIvar = class_getInstanceVariable([self class], "viewModel");
    if (viewModelIvar) {
        id viewModel = object_getIvar(self, viewModelIvar);
        if ([viewModel respondsToSelector:@selector(mediaEntity)]) {
            mediaEntity = [viewModel performSelector:@selector(mediaEntity)];
        } else if ([viewModel respondsToSelector:@selector(status)]) {
            id status = [viewModel performSelector:@selector(status)];
            if ([status respondsToSelector:@selector(entities)]) {
                NSArray* mediaList = [[status entities] media];
                if (mediaList.count > 0) {
                    mediaEntity = mediaList.firstObject;
                }
            }
        }
    }

    if (!mediaEntity) {
        return;
    }

    DownloadInlineButton* downloader = [%c(DownloadInlineButton) new];
    [downloader presentDownloadOptionsForMediaEntities:@[mediaEntity]];
}

%end
