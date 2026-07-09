//
//  Ads.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// Timeline items are removed from the section data before it reaches the data
// view controller, so no empty cells or gaps are left behind. This covers every
// timeline surface (home, profile, search, conversations) regardless of whether
// it renders through a table view or the newer diffable collection view path.

// The promoted state of a status item is only reachable through its Swift-side
// `status` stored property, which is still registered as an ObjC ivar.
static BOOL BHTStatusItemIsPromoted(id item) {
    Ivar statusIvar = class_getInstanceVariable([item class], "status");
    if (!statusIvar) {
        return NO;
    }

    TFNTwitterStatus *status = object_getIvar(item, statusIvar);
    return [status respondsToSelector:@selector(isPromoted)] && status.isPromoted;
}

static BOOL BHTScribeItemIsPromoted(id item) {
    if (![item respondsToSelector:@selector(scribeItem)]) {
        return NO;
    }

    NSDictionary *scribeItem = [item performSelector:@selector(scribeItem)];
    return [scribeItem isKindOfClass:[NSDictionary class]] && scribeItem[@"promoted_id"] != nil;
}

static BOOL BHTIsModuleHeader(id item) {
    return [NSStringFromClass([BHT_unwrapDataViewItem(item) classForCoder]) isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"];
}

static BOOL BHTIsModuleFooter(id item) {
    return [NSStringFromClass([BHT_unwrapDataViewItem(item) classForCoder]) isEqualToString:@"TwitterURT.URTModuleFooterViewModel"];
}

static BOOL BHTShouldHideItem(id item, NSString *location) {
    item = BHT_unwrapDataViewItem(item);
    NSString *className = NSStringFromClass([item classForCoder]);

    if ([BHTSettings boolForKey:@"hide_promoted"]) {
        if ([item isKindOfClass:objc_getClass("T1URTTimelineStatusItemViewModel")] && BHTStatusItemIsPromoted(item)) {
            return YES;
        }

        if ([className isEqualToString:@"TwitterURT.URTTimelineGoogleNativeAdViewModel"]) {
            return YES;
        }

        if (([className isEqualToString:@"TwitterURT.URTTimelineTrendViewModel"] || [className isEqualToString:@"TwitterURT.URTTimelineEventSummaryViewModel"]) && BHTScribeItemIsPromoted(item)) {
            return YES;
        }
    }

    if ([BHTSettings boolForKey:@"hide_premium_offer"]) {
        if ([className isEqualToString:@"TwitterURT.URTTimelineMessageItemViewModel"]) {
            return YES;
        }
    }

    if ([BHTSettings boolForKey:@"hide_trend_videos"] && [location isEqualToString:@"OTHER"]) {
        if ([className isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"]) {
            return YES;
        }
    }

    return NO;
}

static NSArray *BHTFilteredSections(TFNItemsDataViewController *dataViewController, NSArray *sections) {
    if (!([BHTSettings boolForKey:@"hide_promoted"] || [BHTSettings boolForKey:@"hide_premium_offer"] || [BHTSettings boolForKey:@"hide_trend_videos"])) {
        return sections;
    }

    NSString *location = [dataViewController respondsToSelector:@selector(adDisplayLocation)] ? dataViewController.adDisplayLocation : nil;

    BOOL modified = NO;
    NSMutableArray *filteredSections = [NSMutableArray arrayWithCapacity:sections.count];

    for (id section in sections) {
        if (![section isKindOfClass:[NSArray class]]) {
            [filteredSections addObject:section];
            continue;
        }

        NSArray *items = section;
        NSUInteger count = items.count;
        NSMutableIndexSet *removed = [NSMutableIndexSet indexSet];

        for (NSUInteger i = 0; i < count; i++) {
            if (BHTShouldHideItem(items[i], location)) {
                [removed addIndex:i];
            }
        }

        if (removed.count == 0) {
            [filteredSections addObject:section];
            continue;
        }

        // A module renders as a consecutive run of header, content, footer. When
        // a module's content is removed entirely, drop its header and footer too.
        for (NSUInteger i = 0; i < count; i++) {
            if ([removed containsIndex:i] || !BHTIsModuleHeader(items[i])) {
                continue;
            }

            NSUInteger contentCount = 0;
            BOOL contentRemoved = YES;
            NSUInteger j = i + 1;
            while (j < count && !BHTIsModuleHeader(items[j]) && !BHTIsModuleFooter(items[j])) {
                contentCount++;
                if (![removed containsIndex:j]) {
                    contentRemoved = NO;
                }
                j++;
            }

            if (contentCount > 0 && contentRemoved) {
                [removed addIndex:i];
                if (j < count && BHTIsModuleFooter(items[j])) {
                    [removed addIndex:j];
                }
            }
        }

        NSMutableArray *keptItems = [items mutableCopy];
        [keptItems removeObjectsAtIndexes:removed];
        modified = YES;

        if (keptItems.count > 0) {
            [filteredSections addObject:keptItems];
        }
    }

    return modified ? filteredSections : sections;
}

%hook TFNItemsDataViewController

- (void)setSections:(NSArray *)sections restoreScrollPosition:(BOOL)restoreScrollPosition {
    %orig(BHTFilteredSections(self, sections), restoreScrollPosition);
}

- (void)updateSections:(NSArray *)sections reconfigureItemIdentifiers:(NSArray *)identifiers withRowAnimation:(long long)animation completion:(id)completion {
    %orig(BHTFilteredSections(self, sections), identifiers, animation, completion);
}

%end

%hook TFNTwitterStatus

- (_Bool)isCardHidden {
    return ([BHTSettings boolForKey:@"hide_promoted"] && [self isPromoted]) ? true : %orig;
}

%end
