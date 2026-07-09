//
//  RefreshSounds.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: - Restore Pull-To-Refresh Sounds

// 12.3's TFNPullToRefreshControl has no built-in sound path (no soundEffects gate,
// no bundled psst/pop assets), so we play the tweak-bundled sounds ourselves at the
// control's state transitions.

typedef NS_ENUM(NSInteger, BHTRefreshSound) {
    BHTRefreshSoundPull = 0, // Dragging down past the threshold to refresh
    BHTRefreshSoundPop  = 1  // Manual refresh completed
};

@interface TFNPullToRefreshControl : UIView
- (unsigned long long)_status;
@end

static void BHT_PlayRefreshSound(BHTRefreshSound type) {
    // SystemSoundIDs are a global audio resource rather than per-control state, so
    // caching them in statics keyed by sound type is correct and avoids re-decoding.
    static SystemSoundID sounds[2] = {0, 0};
    static BOOL initialized[2] = {NO, NO};

    if (!initialized[type]) {
        NSString *soundFile = (type == BHTRefreshSoundPull) ? @"psst2.aac" : @"pop.aac";
        NSURL *soundURL = [[BHTBundle sharedBundle] pathForFile:soundFile];

        if (soundURL && AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &sounds[type]) == kAudioServicesNoError) {
            initialized[type] = YES;
        }
    }

    if (initialized[type]) {
        AudioServicesPlaySystemSound(sounds[type]);
    }
}

// Every status transition funnels through -_setStatus:fromScrolling:, so it's the
// single closest-to-source seam: a drag past the threshold commits a refresh
// (status 1, fromScrolling), and -setLoading:completion: clears it (status 0) once
// the refresh finishes.
%hook TFNPullToRefreshControl

// Whether the in-flight refresh was started by the user dragging. Per-instance
// (several scroll views can each own a control), so it lives on the instance rather
// than in a static. Gates the completion "pop" to manual pulls only.
static char kManualRefreshKey;

- (void)_setStatus:(unsigned long long)status fromScrolling:(BOOL)fromScrolling {
    BOOL wasActive = ([self _status] == 1);

    %orig;

    if (status == 1 && !wasActive && fromScrolling) {
        BHT_PlayRefreshSound(BHTRefreshSoundPull);
        objc_setAssociatedObject(self, &kManualRefreshKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (status == 0 && wasActive) {
        if ([objc_getAssociatedObject(self, &kManualRefreshKey) boolValue]) {
            BHT_PlayRefreshSound(BHTRefreshSoundPop);
        }
        objc_setAssociatedObject(self, &kManualRefreshKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end

%ctor {
    // AudioToolbox isn't in the tweak's linked frameworks; bind its symbols lazily.
    dlopen("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", RTLD_LAZY);

    %init;
}
