//
//  BHCustomTabBarUtility.m
//  BHTwitter
//
//  Created by Bandar Alruwaili on 10/12/2023.
//

#import "BHCustomTabBarUtility.h"
#import "Headers/T1Headers.h"

// The Home tab is the app's landing surface, so it is always kept visible, pinned
// first, and can never end up in the hidden list.
NSString * const BHCustomTabBarHomePageID = @"home";

NSString * const BHTabPageKey  = @"page";
NSString * const BHTabTitleKey = @"title";
NSString * const BHTabImageKey = @"image";

static NSString * const kVisibleKey  = @"bh_tabs_visible";
static NSString * const kHiddenKey    = @"bh_tabs_hidden";
static NSString * const kRegistryKey = @"bh_tab_registry";

@implementation BHCustomTabBarUtility

#pragma mark - Live capture

// Ordered union of every tab seen this session, so a tab that briefly drops out of
// a tab bar update isn't forgotten while the editor is open.
+ (NSMutableArray<NSDictionary *> *)registry {
    static NSMutableArray<NSDictionary *> *registry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registry = [NSMutableArray array];
        NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:kRegistryKey];
        if (saved) {
            [registry addObjectsFromArray:saved];
        }
    });
    return registry;
}

+ (void)recordTabViews:(NSArray *)tabViews {
    NSMutableArray<NSDictionary *> *registry = [self registry];
    BOOL changed = NO;

    for (T1TabView *tabView in tabViews) {
        NSString *page = tabView.scribePage;
        if (page.length == 0) {
            continue;
        }

        NSString *title = tabView.title.length ? tabView.title : page;
        NSString *image = tabView.imageName ?: @"";
        NSDictionary *entry = @{ BHTabPageKey: page, BHTabTitleKey: title, BHTabImageKey: image };

        NSInteger existing = NSNotFound;
        for (NSInteger i = 0; i < (NSInteger)registry.count; i++) {
            if ([registry[i][BHTabPageKey] isEqualToString:page]) {
                existing = i;
                break;
            }
        }

        if (existing == NSNotFound) {
            [registry addObject:entry];
            changed = YES;
        } else if (![registry[existing] isEqualToDictionary:entry]) {
            registry[existing] = entry;
            changed = YES;
        }
    }

    if (changed) {
        [[NSUserDefaults standardUserDefaults] setObject:[registry copy] forKey:kRegistryKey];
    }
}

+ (NSArray<NSDictionary *> *)availableTabs {
    return [[self registry] copy];
}

+ (NSDictionary *)metadataForPage:(NSString *)pageID {
    for (NSDictionary *entry in [self registry]) {
        if ([entry[BHTabPageKey] isEqualToString:pageID]) {
            return entry;
        }
    }
    return nil;
}

#pragma mark - Selection

+ (NSArray<NSString *> *)visiblePageIDsInOrder {
    NSArray<NSString *> *visible = [[NSUserDefaults standardUserDefaults] stringArrayForKey:kVisibleKey];
    if (!visible) {
        return nil;
    }

    NSMutableArray<NSString *> *pageIDs = [visible mutableCopy];
    // Home is always visible and always first.
    [pageIDs removeObject:BHCustomTabBarHomePageID];
    [pageIDs insertObject:BHCustomTabBarHomePageID atIndex:0];
    return pageIDs;
}

+ (NSArray<NSString *> *)hiddenPageIDs {
    NSArray<NSString *> *hidden = [[NSUserDefaults standardUserDefaults] stringArrayForKey:kHiddenKey];
    if (!hidden) {
        return @[];
    }

    NSMutableArray<NSString *> *pageIDs = [hidden mutableCopy];
    [pageIDs removeObject:BHCustomTabBarHomePageID];
    return pageIDs;
}

+ (void)setVisiblePageIDs:(NSArray<NSString *> *)visible hiddenPageIDs:(NSArray<NSString *> *)hidden {
    [[NSUserDefaults standardUserDefaults] setObject:visible forKey:kVisibleKey];
    [[NSUserDefaults standardUserDefaults] setObject:hidden forKey:kHiddenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)resetSelection {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kVisibleKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHiddenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray<NSString *> *)defaultVisiblePageIDs {
    return @[@"home", @"guide", @"ntab", @"messages"];
}

@end
