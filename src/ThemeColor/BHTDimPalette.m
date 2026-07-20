//
//  BHTDimPalette.m
//  NeoFreeBird
//
//  Created by orionblur
//

#import "ThemeColor/BHTDimPalette.h"
#import <objc/runtime.h>

BOOL BHTDimThemeEnabled(void) {
    return YES;
}

static UIColor* BHTColorWithRGB(uint32_t rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                            green:((rgb >> 8) & 0xFF) / 255.0
                             blue:(rgb & 0xFF) / 255.0
                            alpha:1.0];
}

// Classic Twitter Dim palette: a navy background, a slightly lighter navy for
// anything elevated/secondary, and a lighter shade still for pressed/selected
// states. Text, links, and accent colors are left alone -- Dim only ever
// changed the background family, never the foreground. Exposed (not static)
// so Theme.x's UIColor hook can reuse the same three shades.
UIColor* BHTDimBackgroundColor(void) {
    return BHTColorWithRGB(0x15202B);
}
UIColor* BHTDimElevatedBackgroundColor(void) {
    return BHTColorWithRGB(0x192734);
}
UIColor* BHTDimHighlightBackgroundColor(void) {
    return BHTColorWithRGB(0x1C2836);
}

// UIDynamicSystemColor/UIDynamicCatalogColor (the private classes backing
// UIKit's system colors and asset-catalog +colorNamed: colors) never go
// through TAEColorPalette or the named UIColor class methods, so anything
// they draw has to be caught after the fact, once resolved to a flat RGBA
// color. Since we don't know which named color it was, only remap colors
// that plausibly *are* background chrome: fully opaque and achromatic (no
// real hue -- rules out accent colors, media, everything colorful), sitting
// in the narrow near-black band Apple actually uses for dark background
// tones (systemBackground ~0.0, secondarySystemBackground ~0.11,
// tertiarySystemBackground ~0.17). Brighter grays are left untouched, since
// those are far more likely to be label/fill/separator colors that need to
// stay legible rather than become part of the background.
UIColor* _Nullable BHTDimReplacementForResolvedColor(UIColor* resolved) {
    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
    if (![resolved getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return nil;
    }
    if (alpha < 0.99) {
        return nil;
    }

    CGFloat maxComponent = MAX(red, MAX(green, blue));
    CGFloat minComponent = MIN(red, MIN(green, blue));
    if (maxComponent - minComponent > 0.04) {
        return nil;
    }
    if (maxComponent > 0.22) {
        return nil;
    }

    if (maxComponent < 0.05) {
        return BHTDimBackgroundColor();
    }
    if (maxComponent < 0.14) {
        return BHTDimElevatedBackgroundColor();
    }
    return BHTDimHighlightBackgroundColor();
}

// Self-contained white check -- deliberately not UIColor's private
// safari_isCloseToWhite category, which didn't behave reliably here. Grayscale
// colors (e.g. +whiteColor, which resolves via -getWhite:alpha: rather than
// -getRed:green:blue:alpha:) are handled explicitly rather than falling
// through to "not white".
BOOL BHTColorIsCloseToWhite(UIColor* color) {
    if (!color) {
        return NO;
    }

    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        CGFloat white = 0;
        if (![color getWhite:&white alpha:&alpha]) {
            return NO;
        }
        red = green = blue = white;
    }
    if (alpha < 0.99) {
        return NO;
    }

    CGFloat minComponent = MIN(red, MIN(green, blue));
    return minComponent > 0.9;
}

// The resolvedColorWithTraitCollection: hooks only ever see a color instance,
// never the view it's attached to, so a view-level exemption (e.g. skipping
// TFNButton in a didMoveToWindow hook) can't stop those hooks from still
// recoloring whatever the view's own backgroundColor already was. Marking
// the exact color instance here, from the view's -setBackgroundColor:
// override, gives both layers a shared signal to check.
static const void* kBHTDimExemptColorKey = &kBHTDimExemptColorKey;

void BHTMarkColorDimExempt(UIColor* color) {
    if (!color) {
        return;
    }
    objc_setAssociatedObject(color, kBHTDimExemptColorKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

BOOL BHTColorIsDimExempt(UIColor* color) {
    if (!color) {
        return NO;
    }
    return [objc_getAssociatedObject(color, kBHTDimExemptColorKey) boolValue];
}

@interface BHTDimPaletteProxy ()
@property (nonatomic, strong) id realPalette;
@end

@implementation BHTDimPaletteProxy

+ (instancetype)proxyWithPalette:(id)palette {
    BHTDimPaletteProxy* proxy = [BHTDimPaletteProxy alloc];
    proxy.realPalette = palette;
    return proxy;
}

#pragma mark - Forwarding

// Anything we don't explicitly override below (text, links, accents,
// dividers, primaryColorForOption:, ...) goes straight through to the real
// palette untouched via this fast path.
- (id)forwardingTargetForSelector:(SEL)selector {
    return self.realPalette;
}

// NSProxy's -respondsToSelector:/-conformsToProtocol:/-isKindOfClass: are not
// implemented in terms of -forwardingTargetForSelector: -- they're "real"
// methods on NSProxy itself, so they never reach our overrides above and
// instead fall into the slow invocation-based forwarding path below. Swift's
// dynamic protocol casts (`as? TAEColorPalette`) call -conformsToProtocol:
// directly, so without an explicit override here the proxy answers NO/crashes
// instead of transparently reporting whatever the real palette would.
- (BOOL)respondsToSelector:(SEL)selector {
    return [super respondsToSelector:selector] || [self.realPalette respondsToSelector:selector];
}

- (BOOL)conformsToProtocol:(Protocol*)protocol {
    return [self.realPalette conformsToProtocol:protocol];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [self.realPalette isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [self.realPalette isMemberOfClass:aClass];
}

- (Class)class {
    return [self.realPalette class];
}

// Slow-path forwarding: a safety net for anything the fast path above
// doesn't catch (e.g. selectors NSProxy itself implements).
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    return [self.realPalette methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation*)invocation {
    [invocation invokeWithTarget:self.realPalette];
}

#pragma mark - Overridden background family

- (UIColor*)backgroundColor {
    return BHTDimBackgroundColor();
}
- (UIColor*) backgroundPrimary {
    return BHTDimBackgroundColor();
}
- (UIColor*)darkBackgroundColor {
    return BHTDimBackgroundColor();
}
- (UIColor*)cardHeaderBackgroundColor {
    return BHTDimBackgroundColor();
}
- (UIColor*)modalSheetBackgroundColor {
    return BHTDimBackgroundColor();
}
- (UIColor*)messagingBackgroundColor {
    return BHTDimBackgroundColor();
}

- (UIColor*)secondaryBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)faintBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)itemDarkBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)elevatedBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)toastsBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)tileBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)cardDetailsBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)premiumTiersCardBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)tweetConversationAdBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)chatTopicBackgroundColor {
    return BHTDimElevatedBackgroundColor();
}
- (UIColor*)dmBubbleIncomingColor {
    return BHTDimElevatedBackgroundColor();
}

- (UIColor*)highlightBackgroundColor {
    return BHTDimHighlightBackgroundColor();
}
- (UIColor*)unreadBackgroundColor {
    return BHTDimHighlightBackgroundColor();
}
- (UIColor*)highlightedStatusBackgroundColor {
    return BHTDimHighlightBackgroundColor();
}
- (UIColor*)statusCellOverlayColor {
    return BHTDimHighlightBackgroundColor();
}
- (UIColor*)dmInboxCellSelectionBackgroundColor {
    return BHTDimHighlightBackgroundColor();
}

@end



