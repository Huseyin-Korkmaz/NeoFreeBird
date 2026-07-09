//
//  TwitterChirpFont.h
//  NeoFreeBird
//
//  Created by nyaathea
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Headers/TAEHeaders.h"

typedef NS_ENUM(NSInteger, TwitterFontStyle) {
    TwitterFontStyleRegular,
    TwitterFontStyleSemibold,
    TwitterFontStyleBold
};

// Pull the real Chirp font straight from Twitter's font group (renamed to
// TFNUIDefaultFontGroup in 12.3) so weights track the app instead of relying on
// fragile variable-font instance names. Fall back to a system font if missing.
static inline UIFont *TwitterChirpFont(TwitterFontStyle style) {
    TFNUIDefaultFontGroup *group = [objc_getClass("TFNUIDefaultFontGroup") sharedFontGroup];

    switch (style) {
        case TwitterFontStyleBold:
            return [group heavyFontOfSize:17] ?: [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
        case TwitterFontStyleSemibold:
            return [group boldFontOfSize:14] ?: [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        case TwitterFontStyleRegular:
        default:
            return [group fontOfSize:12] ?: [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    }
}
