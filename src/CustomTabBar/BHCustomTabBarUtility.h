//
//  BHCustomTabBarUtility.h
//  BHTwitter
//
//  Created by Bandar Alruwaili on 10/12/2023.
//

#import <Foundation/Foundation.h>
#import "BHCustomTabBarItem.h"

NS_ASSUME_NONNULL_BEGIN

// pageID of the Home tab, which is always kept visible.
extern NSString * const BHCustomTabBarHomePageID;

@interface BHCustomTabBarUtility : NSObject
+ (NSArray<NSString *> *)getHiddenTabBars;
@end

NS_ASSUME_NONNULL_END
