//
//  BHCustomTabBarItem.m
//  BHTwitter
//
//  Created by Bandar Alruwaili on 10/12/2023.
//

#import "BHCustomTabBarItem.h"

@implementation BHCustomTabBarItem

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithTitle:(NSString *)title pageID:(NSString *)pageID {
    self = [super init];
    if (self) {
        _title = title;
        _pageID = pageID;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.pageID forKey:@"pageID"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _title = [decoder decodeObjectOfClass:[NSString class] forKey:@"title"];
        _pageID = [decoder decodeObjectOfClass:[NSString class] forKey:@"pageID"];
    }
    return self;
}
@end
