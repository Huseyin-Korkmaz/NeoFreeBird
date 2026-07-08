//
//  BHTHookHelpers.m
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// Helper function for recursive view traversal - OPTIMIZED VERSION
void BH_EnumerateSubviewsRecursively(UIView *view, void (^block)(UIView *currentView)) {
    if (!view || !block) return;

    // Performance optimization: Skip hidden views and their subviews
    if (view.hidden || view.alpha <= 0.01) return;

    block(view);

    // Performance optimization: Limit recursion depth to prevent excessive traversal
    static NSInteger recursionDepth = 0;
    if (recursionDepth > 15) return; // Reasonable depth limit

    recursionDepth++;
    for (UIView *subview in view.subviews) {
        BH_EnumerateSubviewsRecursively(subview, block);
    }
    recursionDepth--;
}

UIColor *BHTCurrentAccentColor(void) {
    Class TAEColorSettingsCls = objc_getClass("TAEColorSettings");
    if (!TAEColorSettingsCls) {
        return [UIColor systemBlueColor];
    }

    id settings = [TAEColorSettingsCls sharedSettings];
    id current = [settings currentColorPalette];
    id palette = [current colorPalette];
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    if ([defs objectForKey:@"bh_color_theme_selectedColor"]) {
        NSInteger opt = [defs integerForKey:@"bh_color_theme_selectedColor"];
        return [palette primaryColorForOption:opt] ?: [UIColor systemBlueColor];
    }

    if ([defs objectForKey:@"T1ColorSettingsPrimaryColorOptionKey"]) {
        NSInteger opt = [defs integerForKey:@"T1ColorSettingsPrimaryColorOptionKey"];
        return [palette primaryColorForOption:opt] ?: [UIColor systemBlueColor];
    }

    return [UIColor systemBlueColor];
}

// Add global class pointer for T1ProfileHeaderViewController
static Class gT1ProfileHeaderViewControllerClass = nil;
static Class gDashHostingControllerClass = nil;

static void BHT_initHostingControllerClasses(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gT1ProfileHeaderViewControllerClass = NSClassFromString(@"T1ProfileHeaderViewController");

        // The full name for the hosting controller is very long and specific.
        gDashHostingControllerClass = NSClassFromString(@"_TtGC7SwiftUI19UIHostingControllerGV10TFNUISwift22HostingEnvironmentViewV11TwitterDash18DashNavigationView__");
    });
}

// Helper function to find the UIViewController managing a UIView
UIViewController* getViewControllerForView(UIView *view) {
    @try {
        // Safety check: Ensure view is valid
        if (!view) {
            return nil;
        }

        UIResponder *responder = view;
        NSInteger maxIterations = 20; // Prevent infinite loops
        NSInteger currentIteration = 0;

        while ((responder = [responder nextResponder]) && currentIteration < maxIterations) {
            currentIteration++;

            // Safety check: Ensure responder is still valid
            if (!responder) {
                break;
            }

            if ([responder isKindOfClass:[UIViewController class]]) {
                return (UIViewController *)responder;
            }
            // Stop if we reach top-level objects like UIWindow or UIApplication without finding a VC
            if ([responder isKindOfClass:[UIWindow class]] || [responder isKindOfClass:[UIApplication class]]) {
                break;
            }
        }
        return nil;
    } @catch (NSException *exception) {
        NSLog(@"[BHTwitter] Exception in getViewControllerForView: %@", exception);
        return nil;
    }
}

// Helper function to check if a view is inside T1ProfileHeaderViewController
BOOL isViewInsideT1ProfileHeaderViewController(UIView *view) {
    BHT_initHostingControllerClasses();
    if (!gT1ProfileHeaderViewControllerClass) {
        return NO;
    }
    UIViewController *vc = getViewControllerForView(view);
    if (!vc) return NO;

    UIViewController *parent = vc; // Start with the direct VC
    while (parent) {
        if ([parent isKindOfClass:gT1ProfileHeaderViewControllerClass]) return YES;
        parent = parent.parentViewController;
    }
    UIViewController *presenting = vc.presentingViewController; // Check presenting chain from direct VC
    while(presenting){
        if([presenting isKindOfClass:gT1ProfileHeaderViewControllerClass]) return YES;
        if(presenting.presentingViewController){
            // Check containers in the presenting chain
            if([presenting isKindOfClass:[UINavigationController class]]){
                UINavigationController *nav = (UINavigationController*)presenting;
                for(UIViewController *childVc in nav.viewControllers){
                    if([childVc isKindOfClass:gT1ProfileHeaderViewControllerClass]) return YES;
                }
            }
            presenting = presenting.presentingViewController;
        } else {
            // Final check on the root of the presenting chain for container
            if([presenting isKindOfClass:[UINavigationController class]]){
                 UINavigationController *nav = (UINavigationController*)presenting;
                 for(UIViewController *childVc in nav.viewControllers){
                     if([childVc isKindOfClass:gT1ProfileHeaderViewControllerClass]) return YES;
                 }
            }
            break;
        }
    }
    return NO;
}

// Helper function to check if a view is inside the Dash Hosting Controller
BOOL isViewInsideDashHostingController(UIView *view) {
    BHT_initHostingControllerClasses();
    if (!gDashHostingControllerClass) {
        return NO;
    }
    UIViewController *vc = getViewControllerForView(view);
    if (!vc) return NO;

    UIViewController *parent = vc; // Start with the direct VC
    while (parent) {
        if ([parent isKindOfClass:gDashHostingControllerClass]) return YES;
        parent = parent.parentViewController;
    }
    UIViewController *presenting = vc.presentingViewController; // Check presenting chain from direct VC
    while(presenting){
        if([presenting isKindOfClass:gDashHostingControllerClass]) return YES;
        if(presenting.presentingViewController){
            // Check containers in the presenting chain
            if([presenting isKindOfClass:[UINavigationController class]]){
                UINavigationController *nav = (UINavigationController*)presenting;
                for(UIViewController *childVc in nav.viewControllers){
                    if([childVc isKindOfClass:gDashHostingControllerClass]) return YES;
                }
            }
            presenting = presenting.presentingViewController;
        } else {
             // Final check on the root of the presenting chain for container
             if([presenting isKindOfClass:[UINavigationController class]]){
                 UINavigationController *nav = (UINavigationController*)presenting;
                 for(UIViewController *childVc in nav.viewControllers){
                     if([childVc isKindOfClass:gDashHostingControllerClass]) return YES;
                 }
            }
            break;
        }
    }
    return NO;
}
