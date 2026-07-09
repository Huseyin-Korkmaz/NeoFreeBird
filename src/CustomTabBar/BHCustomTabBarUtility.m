//
//  BHCustomTabBarUtility.m
//  BHTwitter
//
//  Created by Bandar Alruwaili on 10/12/2023.
//

#import "BHCustomTabBarUtility.h"

// The Home tab is the app's landing surface, so it is always kept visible and
// can never end up in the hidden list.
NSString * const BHCustomTabBarHomePageID = @"home";

@implementation BHCustomTabBarUtility

+ (NSArray<NSString *> *)getHiddenTabBars {
    NSData *savedItems = [[NSUserDefaults standardUserDefaults] objectForKey:@"hidden"];
    if (!savedItems) {
        return nil;
    }

    NSArray<BHCustomTabBarItem *> *savedList = [NSKeyedUnarchiver unarchivedArrayOfObjectsOfClass:[BHCustomTabBarItem class]
                                                                                        fromData:savedItems
                                                                                           error:nil];
    if (!savedList) {
        return nil;
    }

    NSMutableArray<NSString *> *pageIDs = [NSMutableArray array];
    for (BHCustomTabBarItem *item in savedList) {
        if ([item.pageID isEqualToString:BHCustomTabBarHomePageID]) {
            continue;
        }
        [pageIDs addObject:item.pageID];
    }
    return pageIDs;
}
@end
