//
//  RefreshSounds.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: - Restore Pull-To-Refresh Sounds

// Helper function to play sounds since we can't directly call methods on TFNPullToRefreshControl
static void PlayRefreshSound(int soundType) {
    static SystemSoundID sounds[2] = {0, 0};
    static BOOL soundsInitialized[2] = {NO, NO};

    // Ensure the sounds are only initialized once per type
    if (!soundsInitialized[soundType]) {
        NSString *soundFile = nil;
        if (soundType == 0) {
            // Sound when pulling down
            soundFile = @"psst2.aac";
        } else if (soundType == 1) {
            // Sound when refresh completes
            soundFile = @"pop.aac";
        }

        if (soundFile) {
            NSURL *soundURL = [[BHTBundle sharedBundle] pathForFile:soundFile];
            if (soundURL) {
                OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &sounds[soundType]);
                if (status == kAudioServicesNoError) {
                    soundsInitialized[soundType] = YES;
                } else {
                    NSLog(@"[BHTwitter] Failed to initialize sound %@ (type %d), status: %d", soundFile, soundType, (int)status);
                }
            } else {
                NSLog(@"[BHTwitter] Could not find sound file: %@", soundFile);
            }
        }
    }

    // Play the sound if it was successfully initialized
    if (soundsInitialized[soundType]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AudioServicesPlaySystemSound(sounds[soundType]);
        });
    }
}

%hook TFNPullToRefreshControl

// Track state with instance-specific variables using associated objects
static char kPreviousLoadingStateKey;
static char kManualRefreshInProgressKey;

// Always enable sound effects
+ (_Bool)_areSoundEffectsEnabled {
    return YES;
}

// Hook the simple loading property setter
- (void)setLoading:(_Bool)loading {
    static BOOL previousLoading = NO;
    static BOOL manualRefresh = NO;

    if (!loading && previousLoading && manualRefresh) {
        PlayRefreshSound(1);
        manualRefresh = NO;
    }

    if (!loading && previousLoading) {
        manualRefresh = NO;
    } else if (loading && !previousLoading) {
        // This is likely a manual refresh
        manualRefresh = YES;
    }

    previousLoading = loading;
    %orig;
}

// Hook the completion-based loading setter
- (void)setLoading:(_Bool)loading completion:(void(^)(void))completion {
    // Get previous loading state
    NSNumber *previousLoadingState = objc_getAssociatedObject(self, &kPreviousLoadingStateKey);
    BOOL wasLoading = previousLoadingState ? [previousLoadingState boolValue] : NO;

    // Check if we're in a manual refresh
    NSNumber *manualRefresh = objc_getAssociatedObject(self, &kManualRefreshInProgressKey);
    BOOL isManualRefresh = manualRefresh ? [manualRefresh boolValue] : NO;

    %orig;

    // Store the new state AFTER calling original
    objc_setAssociatedObject(self, &kPreviousLoadingStateKey, @(loading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // If loading went from YES to NO AND we're in a manual refresh, play pop sound
    if (wasLoading && !loading && isManualRefresh) {
        PlayRefreshSound(1);
        // Clear the manual refresh flag
        objc_setAssociatedObject(self, &kManualRefreshInProgressKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (!wasLoading && loading) {
        NSLog(@"[BHTwitter] Loading changed from NO to YES (completion) - refresh started");
    }
}

// Detect manual pull-to-refresh and play pull sound
- (void)_setStatus:(unsigned long long)status fromScrolling:(_Bool)fromScrolling {
    %orig;

    if (status == 1 && fromScrolling) {
        PlayRefreshSound(0);

        // Mark that we're in a manual refresh
        objc_setAssociatedObject(self, &kManualRefreshInProgressKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // Mark that loading started (even though setLoading: might not be called with loading=1)
        objc_setAssociatedObject(self, &kPreviousLoadingStateKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end

%ctor {
    // Import AudioServices framework
    dlopen("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", RTLD_LAZY);

    %init;
}
