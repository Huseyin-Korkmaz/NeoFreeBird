//
//  BHTHookHelpers.m
//  NeoFreeBird
//

#import "HookHelpers.h"

void EnumerateSubviewsRecursively(UIView* view,
                                  void (^block)(UIView* currentView)) {
    if (!view || !block)
        return;

    // Hidden branches never need live restyling, so skip them entirely.
    if (view.hidden || view.alpha <= 0.01)
        return;

    block(view);

    // Depth cap; a static counter is fine since traversal only runs on the main
    // thread.
    static NSInteger recursionDepth = 0;
    if (recursionDepth > 15)
        return;

    recursionDepth++;
    for (UIView* subview in view.subviews) {
        EnumerateSubviewsRecursively(subview, block);
    }
    recursionDepth--;
}

// Module content reaches the section arrays wrapped in TFNDataViewItem (the
// real view model is its -item); standalone timeline items are the view model
// directly.
id unwrapDataViewItem(id item) {
    if ([item isKindOfClass:objc_getClass("TFNDataViewItem")] &&
        [item respondsToSelector:@selector(item)]) {
        return [item performSelector:@selector(item)];
    }

    return item;
}

UIColor* CurrentAccentColor(void) {
    Class TAEColorSettingsCls = objc_getClass("TAEColorSettings");
    if (!TAEColorSettingsCls) {
        return [UIColor systemBlueColor];
    }

    id settings = [TAEColorSettingsCls sharedSettings];
    id current = [settings currentColorPalette];
    id palette = [current colorPalette];
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];

    // The tweak's stored pick wins over Twitter's own colour option.
    if ([defs objectForKey:@"bh_color_theme_selectedColor"]) {
        NSInteger opt = [defs integerForKey:@"bh_color_theme_selectedColor"];
        return [palette primaryColorForOption:opt] ?: [UIColor systemBlueColor];
    }

    if ([defs objectForKey:@"T1ColorSettingsPrimaryColorOptionKey"]) {
        NSInteger opt =
            [defs integerForKey:@"T1ColorSettingsPrimaryColorOptionKey"];
        return [palette primaryColorForOption:opt] ?: [UIColor systemBlueColor];
    }

    return [UIColor systemBlueColor];
}
