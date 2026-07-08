//
//  AppLifecycle.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// ===== Padlock helpers (new) =====

static const NSInteger BHTPadlockOverlayTag = 909;

static NSArray<UIWindow *> *BHT_allActiveWindows(void) {
    NSMutableArray<UIWindow *> *result = [NSMutableArray array];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (!w.hidden) [result addObject:w];
                }
            }
        }
    }
    if (result.count == 0) {
        for (UIWindow *w in UIApplication.sharedApplication.windows) {
            if (!w.hidden) [result addObject:w];
        }
    }
    return result;
}

static UIWindow *BHT_activeKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) return w;
                }
                for (UIWindow *w in ws.windows) {
                    if (!w.hidden) return w;
                }
            }
        }
    }
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) return w;
    }
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (!w.hidden) return w;
    }
    return nil;
}

static UIViewController *BHT_topViewController(UIViewController *root) {
    if (!root) return nil;
    UIViewController *vc = root;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    if ([vc isKindOfClass:[UINavigationController class]]) {
        vc = ((UINavigationController *)vc).visibleViewController ?: vc;
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        UIViewController *sel = ((UITabBarController *)vc).selectedViewController;
        if (sel) vc = sel;
    }
    return vc;
}

static void BHT_showPadlockOverlay(void) {
    UIWindow *window = BHT_activeKeyWindow();
    if (!window) return;

    for (UIWindow *w in BHT_allActiveWindows()) {
        for (UIView *v in w.subviews) {
            if (v.tag == BHTPadlockOverlayTag) [v removeFromSuperview];
        }
    }

    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = UIColor.systemBackgroundColor;
    overlay.userInteractionEnabled = YES;
    overlay.tag = BHTPadlockOverlayTag;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = UIColor.labelColor;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Locked";
    label.textColor = UIColor.labelColor;
    label.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;

    [overlay addSubview:icon];
    [overlay addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-20],
        [label.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [label.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:8]
    ]];

    [window addSubview:overlay];
}

static void BHT_removePadlockOverlay(void) {
    for (UIWindow *w in BHT_allActiveWindows()) {
        NSMutableArray<UIView *> *toRemove = [NSMutableArray array];
        for (UIView *v in w.subviews) {
            if (v.tag == BHTPadlockOverlayTag) [toRemove addObject:v];
        }
        for (UIView *v in toRemove) [v removeFromSuperview];
    }
}

static BOOL BHT_isAuthenticated(void) {
    NSDictionary *keychainData = [[keychain shared] getData];
    if (!keychainData) return NO;
    id val = keychainData[@"isAuthenticated"];
    return [val respondsToSelector:@selector(boolValue)] ? [val boolValue] : NO;
}

static void BHT_setAuthenticated(BOOL yes) {
    [[keychain shared] saveDictionary:@{@"isAuthenticated": @(yes)}];
}

static void BHT_presentAuthIfNeeded(void) {
    if (BHT_isAuthenticated()) {
        BHT_removePadlockOverlay();
        return;
    }

    UIWindow *window = BHT_activeKeyWindow();
    if (!window) {
        BHT_showPadlockOverlay();
        return;
    }

    UIViewController *root = window.rootViewController;
    if (!root) {
        window.rootViewController = [UIViewController new];
        root = window.rootViewController;
    }
    UIViewController *host = BHT_topViewController(root);

    AuthViewController *auth = [[AuthViewController alloc] init];
    auth.modalPresentationStyle = UIModalPresentationFullScreen;
    if ([auth respondsToSelector:@selector(setModalInPresentation:)]) {
        auth.modalInPresentation = YES;
    }

    if (host.presentedViewController == nil) {
        [host presentViewController:auth animated:NO completion:nil];
    } else {
        [host dismissViewControllerAnimated:NO completion:^{
            UIViewController *newTop = BHT_topViewController(root);
            [newTop presentViewController:auth animated:NO completion:nil];
        }];
    }
}
// MARK: App Delegate hooks


%hook T1AppDelegate
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    _Bool orig = %orig;

    [BHTManager cleanCache];
    if ([BHTSettings boolForKey:@"flex_twitter"]) {
        [[%c(FLEXManager) sharedManager] showExplorer];
    }

    // Apply theme immediately after launch - simplified version using our new system
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"bh_color_theme_selectedColor"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Force synchronize our theme with Twitter's internal theme system
            BHT_ensureThemingEngineSynchronized(YES);
        });
    }

    // Start the cookie initialization process with retry mechanism
    if ([BHTSettings boolForKey:@"restore_tweet_labels"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [TweetSourceHelper initializeCookiesWithRetry];
        });
    }

    return orig;
}

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;

    // Re-apply theming and other existing logic …
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"bh_color_theme_selectedColor"]) {
        BHT_ensureThemingEngineSynchronized(YES);
    }
    if ([BHTSettings boolForKey:@"restore_tweet_labels"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [TweetSourceHelper initializeCookiesWithRetry];
        });
    }

    BHT_prewarmWebCookiesIfNeeded();

    if ([BHTSettings boolForKey:@"padlock"]) {
        if (BHT_isAuthenticated()) {
            BHT_removePadlockOverlay();
        } else {
            BHT_showPadlockOverlay();
            dispatch_async(dispatch_get_main_queue(), ^{
                BHT_presentAuthIfNeeded();
            });
        }

        // Safety recheck in case Face ID completes very quickly
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (BHT_isAuthenticated()) {
                BHT_removePadlockOverlay();
            }
        });
    } else {
        BHT_removePadlockOverlay();
    }
}

- (void)applicationWillResignActive:(id)arg1 {
    %orig;

    if ([BHTSettings boolForKey:@"restore_tweet_labels"]) {
        [TweetSourceHelper cleanupTimersForBackground];
    }

    if ([BHTSettings boolForKey:@"padlock"]) {
        // Cover UI immediately
        BHT_showPadlockOverlay();
        // Mark unauthenticated so a reopen from background will prompt again
        BHT_setAuthenticated(NO);
    }

    if ([BHTSettings boolForKey:@"flex_twitter"]) {
        [[%c(FLEXManager) sharedManager] showExplorer];
    }
}

- (void)applicationDidEnterBackground:(id)arg1 {
    %orig;

    if ([BHTSettings boolForKey:@"padlock"]) {
        // Redundant, ensures state is locked while backgrounded
        BHT_setAuthenticated(NO);
        BHT_showPadlockOverlay();
    }
}

- (void)applicationWillEnterForeground:(id)arg1 {
    %orig;

    if ([BHTSettings boolForKey:@"padlock"]) {
        // Keep UI covered during transition
        BHT_showPadlockOverlay();
    }
}

- (void)applicationWillTerminate:(id)arg1 {
    %orig;
    if ([BHTSettings boolForKey:@"padlock"]) {
        BHT_setAuthenticated(NO);
        BHT_removePadlockOverlay();
    }
}

%end

%hook AuthViewController

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    if (BHT_isAuthenticated()) {
        BHT_removePadlockOverlay();
    }
}

%end
// MARK: Restore Launch Animation

%hook T1AppDelegate
+ (id)launchTransitionProvider {
    Class T1AppLaunchTransitionClass = NSClassFromString(@"T1AppLaunchTransition");
    if (T1AppLaunchTransitionClass) {
        return [[T1AppLaunchTransitionClass alloc] init];
    }
    return nil;
}
%end

// MARK: Remove the X-shaped reveal mask from the animated launch screen
// The animated launch screen masks its container layer with an X-shaped hole
// and grows it to reveal the app through an X-shaped portal. Detach that mask
// so the logo zoom is kept but the splash simply fades out instead.

%hook T1AnimatedLaunchScreenView

- (void)layoutSubviews {
    %orig;

    for (UIView *sub in ((UIView *)self).subviews) {
        sub.layer.mask = nil;
    }
}

- (void)animateRevealWithCompletion:(id)completion {
    for (UIView *sub in ((UIView *)self).subviews) {
        sub.layer.mask = nil;
    }

    [UIView animateWithDuration:0.5 animations:^{
        for (UIView *sub in ((UIView *)self).subviews) {
            sub.backgroundColor = [UIColor clearColor];
        }
    }];

    %orig;
}

%end
