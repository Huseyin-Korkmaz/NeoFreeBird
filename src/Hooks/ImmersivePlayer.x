//
//  ImmersivePlayer.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: - Immersive Player Timestamp

// The immersive player builds its overlay from plugin views that each derive
// their visibility from a shared ImmersiveCardState. The progress label
// ("0:07 / 0:30") is a stock plugin, but its update handler only shows it when
// isPortraitOrientation is false, so the portrait video feed never sees it.
// Recomputing the alpha from displayMode alone restores the label in portrait
// while keeping it tied to the controls, which hide through displayMode.
//
// displayMode is a Swift enum stored as an 8-byte case index followed by a
// discriminator tag (0 = the repliesPanning payload case, 1 = an empty case).
// Empty cases: regular = 0, repliesOpen = 1, repliesCompletelyOpen = 2,
// controlsHidden = 3, scrubbing = 4, statusExpanded = 5.
static BOOL BHT_progressLabelAlphaFromState(id pluginView, CGFloat *outAlpha) {
    Ivar stateIvar = class_getInstanceVariable([pluginView class], "state");
    if (!stateIvar) {
        return NO;
    }

    uint8_t *state = (uint8_t *)(__bridge void *)pluginView + ivar_getOffset(stateIvar);
    uint64_t displayModeCase = *(uint64_t *)state;
    uint8_t displayModeTag = state[8];

    BOOL visible = displayModeTag == 1 && (displayModeCase < 1 || displayModeCase > 3);
    *outAlpha = visible ? 1.0 : 0.0;
    return YES;
}

%hook _TtC14T1TwitterSwift32ImmersiveProgressLabelPluginView

- (void)setAlpha:(CGFloat)alpha {
    if ([BHTSettings boolForKey:@"restore_video_timestamp"]) {
        CGFloat stateAlpha;
        if (BHT_progressLabelAlphaFromState(self, &stateAlpha)) {
            alpha = stateAlpha;
        }
    }

    %orig(alpha);
}

%end
