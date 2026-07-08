//
//  ImmersivePlayer.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// Map to store timestamp labels for each player instance
static NSMapTable<T1ImmersiveFullScreenViewController *, UILabel *> *playerToTimestampMap = nil;

// Performance optimization: Cache for label searches to avoid repeated expensive traversals
static NSMapTable<T1ImmersiveFullScreenViewController *, NSNumber *> *labelSearchCache = nil;
static NSTimeInterval lastCacheInvalidation = 0;
static const NSTimeInterval CACHE_INVALIDATION_INTERVAL = 10.0; // 10 seconds
// MARK: - Immersive Player Timestamp

%hook T1ImmersiveFullScreenViewController

// Forward declare the new helper method for visibility within this hook block
- (BOOL)BHT_findAndPrepareTimestampLabelForVC:(T1ImmersiveFullScreenViewController *)activePlayerVC;

// Helper method to find, style, and map the timestamp label for a given VC instance
%new - (BOOL)BHT_findAndPrepareTimestampLabelForVC:(T1ImmersiveFullScreenViewController *)activePlayerVC {
    if (!playerToTimestampMap || !activePlayerVC || !activePlayerVC.isViewLoaded) {
        return NO;
    }

    // Performance optimization: Check cache first to avoid repeated expensive searches
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastCacheInvalidation > CACHE_INVALIDATION_INTERVAL) {
        if (labelSearchCache) {
            [labelSearchCache removeAllObjects];
        }
        lastCacheInvalidation = currentTime;
    }

    // Initialize cache if needed
    if (!labelSearchCache) {
        labelSearchCache = [NSMapTable weakToStrongObjectsMapTable];
    }

    UILabel *timestampLabel = [playerToTimestampMap objectForKey:activePlayerVC];

    // Performance optimization: Only do fresh find if really necessary
    BOOL needsFreshFind = (!timestampLabel || !timestampLabel.superview || ![timestampLabel.superview isDescendantOfView:activePlayerVC.view]);
    if (timestampLabel && timestampLabel.superview &&
        (![timestampLabel.text containsString:@":"] || ![timestampLabel.text containsString:@"/"])) {
        needsFreshFind = YES;
        [playerToTimestampMap removeObjectForKey:activePlayerVC];
        timestampLabel = nil;
    }

    if (needsFreshFind) {
        // Performance optimization: Check if we recently failed to find a label for this VC
        NSNumber *lastSearchResult = [labelSearchCache objectForKey:activePlayerVC];
        if (lastSearchResult && ![lastSearchResult boolValue]) {
            return NO;
        }
        __block UILabel *foundCandidate = nil;
        UIView *searchView = activePlayerVC.view;

        // Performance optimization: Limit search scope to likely container views
        __block NSInteger searchCount = 0;
        const NSInteger MAX_SEARCH_COUNT = 100; // Prevent excessive searching

        BH_EnumerateSubviewsRecursively(searchView, ^(UIView *currentView) {
            if (foundCandidate || ++searchCount > MAX_SEARCH_COUNT) return;

            // Performance optimization: Skip views that are unlikely to contain timestamp labels
            NSString *currentViewClass = NSStringFromClass([currentView class]);
            if ([currentViewClass containsString:@"Button"] ||
                [currentViewClass containsString:@"Image"] ||
                [currentViewClass containsString:@"Scroll"]) {
                return;
            }

            if ([currentView isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)currentView;

                // Performance optimization: Quick text validation before hierarchy check
                if (!label.text || label.text.length < 3 ||
                    ![label.text containsString:@":"] || ![label.text containsString:@"/"]) {
                    return;
                }

                UIView *v = label.superview;
                BOOL inImmersiveCardViewContext = NO;
                NSInteger hierarchyDepth = 0;

                while(v && v != searchView.window && v != searchView && hierarchyDepth < 10) {
                    NSString *className = NSStringFromClass([v class]);
                    if ([className isEqualToString:@"T1TwitterSwift.ImmersiveCardView"] || [className hasSuffix:@".ImmersiveCardView"]) {
                        inImmersiveCardViewContext = YES;
                        break;
                    }
                    v = v.superview;
                    hierarchyDepth++;
                }

                if (inImmersiveCardViewContext) {
                    foundCandidate = label;
                }
            }
        });

        if (foundCandidate) {
            timestampLabel = foundCandidate;

            // Don't set the visibility directly - let the player handle it
            // Just style the label for proper appearance

            // Now store it in our map
            [playerToTimestampMap setObject:timestampLabel forKey:activePlayerVC];
            [labelSearchCache setObject:@YES forKey:activePlayerVC];
        } else {
            // Performance optimization: Cache negative results to avoid repeated searches
            [labelSearchCache setObject:@NO forKey:activePlayerVC];
            if ([playerToTimestampMap objectForKey:activePlayerVC]) {
                [playerToTimestampMap removeObjectForKey:activePlayerVC];
            }
            return NO;
        }
    }

    if (timestampLabel && ![objc_getAssociatedObject(timestampLabel, "BHT_StyledTimestamp") boolValue]) {
        timestampLabel.font = [UIFont systemFontOfSize:14.0];
        timestampLabel.textColor = [UIColor whiteColor];
        timestampLabel.textAlignment = NSTextAlignmentCenter;
        timestampLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

        [timestampLabel sizeToFit];
        CGRect currentFrame = timestampLabel.frame;
        CGFloat horizontalPadding = 2.0; // Padding on EACH side
        CGFloat verticalPadding = 12.0; // TOTAL vertical padding (6.0 on each side)

        CGRect newFrame = CGRectMake(
            currentFrame.origin.x - horizontalPadding,
            currentFrame.origin.y - (verticalPadding / 2.0f),
            currentFrame.size.width + (horizontalPadding * 2),
                currentFrame.size.height + verticalPadding
            );

        if (newFrame.size.height < 22.0f) {
            CGFloat heightDiff = 22.0f - newFrame.size.height;
            newFrame.size.height = 22.0f;
            newFrame.origin.y -= heightDiff / 2.0f;
        }
        timestampLabel.frame = newFrame;
        timestampLabel.layer.cornerRadius = newFrame.size.height / 2.0f;
        timestampLabel.layer.masksToBounds = YES;
        objc_setAssociatedObject(timestampLabel, "BHT_StyledTimestamp", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return (timestampLabel != nil && timestampLabel.superview != nil); // Ensure it's also in a superview
}

- (void)immersiveViewController:(id)passedImmersiveViewController showHideNavigationButtons:(_Bool)showButtons {
    // Store the original value for "showButtons"
    BOOL originalShowButtons = showButtons;

    // No longer forcing controls to be visible on first load
    // Let Twitter's player handle everything normally

    // Always pass the original parameter - no overriding
    %orig(passedImmersiveViewController, originalShowButtons);

    T1ImmersiveFullScreenViewController *activePlayerVC = self;

    // The rest of the method remains unchanged
    if (![BHTSettings boolForKey:@"restore_video_timestamp"]) {
        if (playerToTimestampMap) {
            UILabel *labelToManage = [playerToTimestampMap objectForKey:activePlayerVC];
            if (labelToManage) {
                labelToManage.hidden = YES;

            }
        }
        return;
    }

    SEL findAndPrepareSelector = NSSelectorFromString(@"BHT_findAndPrepareTimestampLabelForVC:");
    BOOL labelReady = NO;

    if ([self respondsToSelector:findAndPrepareSelector]) {
        NSMethodSignature *signature = [self methodSignatureForSelector:findAndPrepareSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:findAndPrepareSelector];
        [invocation setTarget:self];
        [invocation setArgument:&activePlayerVC atIndex:2]; // Arguments start at index 2 (0 = self, 1 = _cmd)
        [invocation invoke];
        [invocation getReturnValue:&labelReady];
    } else {

    }

    if (labelReady) {
        UILabel *timestampLabel = [playerToTimestampMap objectForKey:activePlayerVC];
        if (timestampLabel) {
            // Let the timestamp follow the controls visibility, but ensure it matches
            BOOL isVisible = showButtons;


            // Only adjust if there's a mismatch
            if (isVisible && timestampLabel.hidden) {
                // Controls are visible but label is hidden - fix it
                timestampLabel.hidden = NO;
                NSLog(@"[BHTwitter Timestamp] VC %@: Fixing hidden label to match visible controls", activePlayerVC);
            } else if (!isVisible && !timestampLabel.hidden) {
                // Controls are hidden but label is visible - fix it
                NSLog(@"[BHTwitter Timestamp] VC %@: Label is incorrectly visible, will be hidden by player", activePlayerVC);
            }
        } else {
            NSLog(@"[BHTwitter Timestamp] VC %@: Label was ready but map returned nil.", activePlayerVC);
        }
    } else {
        NSLog(@"[BHTwitter Timestamp] VC %@: Label not ready after findAndPrepare.", activePlayerVC);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    T1ImmersiveFullScreenViewController *activePlayerVC = self;

    if ([BHTSettings boolForKey:@"restore_video_timestamp"]) {
        if (!playerToTimestampMap) {
            playerToTimestampMap = [NSMapTable weakToStrongObjectsMapTable];
        }

        // Ensure the label is found and prepared if the view appears.
        [self BHT_findAndPrepareTimestampLabelForVC:activePlayerVC];
    }
}

- (void)playerViewController:(id)playerViewController playerStateDidChange:(NSInteger)state {
    %orig(playerViewController, state);
    T1ImmersiveFullScreenViewController *activePlayerVC = self;

    if (![BHTSettings boolForKey:@"restore_video_timestamp"] || !playerToTimestampMap) {
        return;
    }

    // Always try to find/prepare the label for the current video content.
    // This is crucial if the VC is reused and new video content has loaded.
    BOOL labelFoundAndPrepared = [self BHT_findAndPrepareTimestampLabelForVC:activePlayerVC];

    if (labelFoundAndPrepared) {
        UILabel *timestampLabel = [playerToTimestampMap objectForKey:activePlayerVC];
        if (timestampLabel && timestampLabel.superview && [timestampLabel isDescendantOfView:activePlayerVC.view]) {
            // Determine current intended visibility of controls.
            BOOL controlsShouldBeVisible = NO;
            UIView *playerControls = nil;
            if ([activePlayerVC respondsToSelector:@selector(playerControlsView)]) {
                playerControls = [activePlayerVC valueForKey:@"playerControlsView"];
                if (playerControls && [playerControls respondsToSelector:@selector(alpha)]) {
                    controlsShouldBeVisible = playerControls.alpha > 0.0f;
                }
            }

            // Directly set the label's visibility based on controls
            timestampLabel.hidden = !controlsShouldBeVisible;
        }
    }
}

%end
// MARK: - Timestamp Label Styling via UILabel -setText:

// Helper method to determine if a text is likely a timestamp
static BOOL isTimestampText(NSString *text) {
    if (!text || text.length == 0) {
        return NO;
    }

    // Check for common timestamp patterns like "0:01/0:05" or "00:20/01:30"
    NSRange colonRange = [text rangeOfString:@":"];
    NSRange slashRange = [text rangeOfString:@"/"];

    // Must have both colon and slash
    if (colonRange.location == NSNotFound || slashRange.location == NSNotFound) {
        return NO;
    }

    // Slash should come after colon in a timestamp (e.g., "0:01/0:05")
    if (slashRange.location < colonRange.location) {
        return NO;
    }

    // Should have another colon after the slash
    NSRange secondColonRange = [text rangeOfString:@":" options:0 range:NSMakeRange(slashRange.location, text.length - slashRange.location)];
    if (secondColonRange.location == NSNotFound) {
        return NO;
    }

    return YES;
}

%hook UILabel

- (void)setText:(NSString *)text {
    %orig(text);

    // Skip processing if feature is disabled
    if (![BHTSettings boolForKey:@"restore_video_timestamp"]) {
        return;
    }

    // Skip if text doesn't match timestamp pattern
    if (!isTimestampText(self.text)) {
        return;
    }

    // Check if already styled
    if ([objc_getAssociatedObject(self, "BHT_StyledTimestamp") boolValue]) {
        return;
    }

    // Find if we're in the correct view context
    UIView *parentView = self.superview;
    BOOL isInImmersiveContext = NO;

    while (parentView) {
        NSString *className = NSStringFromClass([parentView class]);
        if ([className isEqualToString:@"T1TwitterSwift.ImmersiveCardView"] ||
            [className hasSuffix:@".ImmersiveCardView"]) {
            isInImmersiveContext = YES;
            break;
        }
        parentView = parentView.superview;
    }

    if (isInImmersiveContext) {

        // Apply styling - ONLY styling, not visibility
        self.font = [UIFont systemFontOfSize:14.0];
        self.textColor = [UIColor whiteColor];
        self.textAlignment = NSTextAlignmentCenter;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

        // Calculate size and apply padding
        [self sizeToFit];
        CGRect frame = self.frame;
        CGFloat horizontalPadding = 4.0;
        CGFloat verticalPadding = 12.0;

        frame = CGRectMake(
            frame.origin.x - horizontalPadding / 2.0f,
            frame.origin.y - verticalPadding / 2.0f,
            frame.size.width + horizontalPadding,
            frame.size.height + verticalPadding
        );

        // Ensure minimum height
        if (frame.size.height < 22.0f) {
            CGFloat diff = 22.0f - frame.size.height;
            frame.size.height = 22.0f;
            frame.origin.y -= diff / 2.0f;
        }

        self.frame = frame;
        self.layer.cornerRadius = frame.size.height / 2.0f;
        self.layer.masksToBounds = YES;

        // Mark as styled and store reference
        objc_setAssociatedObject(self, "BHT_StyledTimestamp", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end

%ctor {
    %init;

    static dispatch_once_t onceTokenPlayerMap;
    dispatch_once(&onceTokenPlayerMap, ^{
        playerToTimestampMap = [NSMapTable weakToStrongObjectsMapTable];
    });
}
