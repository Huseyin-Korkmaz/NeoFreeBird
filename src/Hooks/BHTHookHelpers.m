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
