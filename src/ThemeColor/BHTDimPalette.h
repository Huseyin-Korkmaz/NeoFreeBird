//
//  BHTDimPalette.h
//  NeoFreeBird
//
//  Created by orionblur
//

#import <UIKit/UIKit.h>

/**
 * Whether the classic Twitter "Dim" recolor should replace the app's native
 * Dark palette. Hardcoded on for now; swap the body for a BHTSettings lookup
 * once there's a settings entry for it.
 */
BOOL BHTDimThemeEnabled(void);

/**
 * The three Dim shades, for direct use where a caller isn't going through the
 * palette proxy below (e.g. overriding UIKit's own dynamic system colors,
 * which are a separate source of "pure black" chrome the TAEColorPalette
 * proxy never sees).
 */
UIColor* BHTDimBackgroundColor(void);
UIColor* BHTDimElevatedBackgroundColor(void);
UIColor* BHTDimHighlightBackgroundColor(void);

/**
 * Best-effort remap for a color that's already been resolved for a trait
 * collection (i.e. flattened to concrete RGBA), used to catch UIKit's
 * private dynamic-color classes (UIDynamicSystemColor, UIDynamicCatalogColor)
 * which never go through TAEColorPalette or the named UIColor class methods.
 * Only touches colors that look like opaque, achromatic background chrome
 * (near-black grays); returns nil -- meaning "leave it alone" -- for
 * anything with real hue, transparency, or brightness outside that band, so
 * text, accents, and translucent overlays are never touched.
 */
UIColor* _Nullable BHTDimReplacementForResolvedColor(UIColor* resolved);

/**
 * Self-contained "is this white/near-white" check, used to keep genuinely
 * white chrome from being force-overwritten by the blanket TFNSolidColorView
 * recolor in Theme.x (that override doesn't go through
 * BHTDimReplacementForResolvedColor's heuristic at all, so it needs its own
 * guard). Deliberately not relying on UIColor's private safari_isCloseToWhite
 * category -- undocumented, and it didn't produce reliable results here.
 */
BOOL BHTColorIsCloseToWhite(UIColor* _Nullable color);

/**
 * -resolvedColorWithTraitCollection: hooks have no notion of which view is
 * asking -- they only ever see the color instance. To exempt a specific
 * view's color from those hooks, mark the exact UIColor instance it's
 * assigned as exempt (e.g. from that view's -setBackgroundColor: override)
 * and have the resolution hooks check it before substituting.
 */
void BHTMarkColorDimExempt(UIColor* _Nullable color);
BOOL BHTColorIsDimExempt(UIColor* _Nullable color);

/**
 * Wraps a live TAEColorPalette-conforming object, substituting Dim's navy
 * background family for the handful of properties it overrides and
 * forwarding everything else (text, links, accents, dividers) untouched to
 * the wrapped palette.
 *
 * The app only ever renders Light or Dark now -- there's no native third
 * state -- so this is how Dim comes back: it recolors Dark rather than
 * adding an option alongside it.
 */
@interface BHTDimPaletteProxy : NSProxy

+ (instancetype)proxyWithPalette:(id)palette;

@end
