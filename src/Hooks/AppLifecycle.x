//
//  AppLifecycle.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: - Padlock helpers

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
    label.text = [[BHTBundle sharedBundle] localizedStringForKey:@"PADLOCK_LOCKED_LABEL"];
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

// MARK: - App Delegate hooks

%hook T1AppDelegate

- (_Bool)application:(__unsafe_unretained UIApplication *)application didFinishLaunchingWithOptions:(__unsafe_unretained id)arg2 {
    _Bool orig = %orig;

    [BHTManager cleanCache];
    if ([BHTSettings boolForKey:@"flex_twitter"]) {
        [[%c(FLEXManager) sharedManager] showExplorer];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        BHT_applySelectedThemeColor();
    });

    return orig;
}

- (void)applicationDidBecomeActive:(__unsafe_unretained id)arg1 {
    %orig;

    BHT_applySelectedThemeColor();
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
    } else {
        BHT_removePadlockOverlay();
    }
}

- (void)applicationWillResignActive:(__unsafe_unretained id)arg1 {
    %orig;

    if ([BHTSettings boolForKey:@"padlock"]) {
        // Cover the UI (and the app-switcher snapshot) and mark unauthenticated so
        // the next activation prompts again; the overlay persists into background.
        BHT_showPadlockOverlay();
        BHT_setAuthenticated(NO);
    }

    if ([BHTSettings boolForKey:@"flex_twitter"]) {
        [[%c(FLEXManager) sharedManager] showExplorer];
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

// MARK: - Restore Launch Animation

// The launch animation reveals the app through a growing X-shaped mask
// (revealMaskLayer / holePathInView); detach it so the logo zoom is kept but the
// splash simply fades out.

static void BHT_stripLaunchRevealMask(UIView *view) {
    // The X-shaped hole lives on the container subview's layer.mask; the top
    // view itself is unmasked, but clear it too for safety.
    view.layer.mask = nil;
    for (UIView *sub in view.subviews) {
        sub.layer.mask = nil;
    }
}

%hook T1AnimatedLaunchScreenView

- (void)layoutSubviews {
    %orig;
    // layoutSubviews re-installs the mask each pass, so re-strip after %orig.
    BHT_stripLaunchRevealMask((UIView *)self);
}

- (void)animateRevealWithCompletion:(id)completion {
    BHT_stripLaunchRevealMask((UIView *)self);

    [UIView animateWithDuration:0.5 animations:^{
        for (UIView *sub in ((UIView *)self).subviews) {
            sub.backgroundColor = [UIColor clearColor];
        }
    }];

    %orig;
}

%end
