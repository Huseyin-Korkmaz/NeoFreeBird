//
//  BHAppIconViewController.m
//  NeoFreeBird
//
//  Created by Bandar Alruwaili on 10/12/2023.
//  Modified by actuallyaridan on 25/05/2025.
//

#import "BHAppIconViewController.h"
#import "BHAppIconItem.h"
#import "BHAppIconCell.h"
#import "Core/BHTBundle.h"
#import "ThemeColor/BHDimPalette.h"
#import <UIKit/UIKit.h>
#import "Core/TwitterChirpFont.h"


@interface BHAppIconViewController () <
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
>
@property (nonatomic, strong) UICollectionView            *appIconCollectionView;
@property (nonatomic, copy)   NSArray<BHAppIconItem *>    *icons;
@end

@implementation BHAppIconViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title =
      [[BHTBundle sharedBundle] localizedStringForKey:@"APP_ICON_NAV_TITLE"];

    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.sectionInset            = UIEdgeInsetsMake(16, 16, 16, 16);
    flow.minimumLineSpacing      = 10;
    flow.minimumInteritemSpacing = 10;

    self.appIconCollectionView = [[UICollectionView alloc]
        initWithFrame:CGRectZero
  collectionViewLayout:flow];
    self.appIconCollectionView.contentInsetAdjustmentBehavior =
      UIScrollViewContentInsetAdjustmentAlways;
    [self.appIconCollectionView registerClass:[BHAppIconCell class]
                   forCellWithReuseIdentifier:[BHAppIconCell reuseIdentifier]];
    [self.appIconCollectionView registerClass:[UICollectionReusableView class]
                   forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                          withReuseIdentifier:@"HeaderView"];
    self.appIconCollectionView.delegate   = self;
    self.appIconCollectionView.dataSource = self;
    self.appIconCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.appIconCollectionView.backgroundColor = [BHDimPalette currentBackgroundColor];

    self.view.backgroundColor = [BHDimPalette currentBackgroundColor];

    [self.view addSubview:self.appIconCollectionView];

    [NSLayoutConstraint activateConstraints:@[
      [self.appIconCollectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
      [self.appIconCollectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.appIconCollectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [self.appIconCollectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self loadAppIcons];
}

// Icons are derived from the app's own Info.plist, so the picker always matches
// whatever the current build actually ships (the primary icon plus every
// declared alternate). The default icon is listed first so it can be restored.
- (void)loadAppIcons {
    NSDictionary *iconsDict =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];

    NSMutableArray<BHAppIconItem *> *items = [NSMutableArray new];

    NSDictionary *primary = iconsDict[@"CFBundlePrimaryIcon"];
    if ([primary isKindOfClass:[NSDictionary class]]) {
        [items addObject:[[BHAppIconItem alloc]
             initWithBundleIconName:primary[@"CFBundleIconName"]
                      iconFileNames:primary[@"CFBundleIconFiles"]
                      isPrimaryIcon:YES]];
    }

    NSDictionary *alternates = iconsDict[@"CFBundleAlternateIcons"];
    if ([alternates isKindOfClass:[NSDictionary class]]) {
        NSArray<NSString *> *sortedKeys =
          [alternates.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        for (NSString *key in sortedKeys) {
            NSDictionary *alt = alternates[key];
            NSString *name = alt[@"CFBundleIconName"] ?: key;
            [items addObject:[[BHAppIconItem alloc]
                 initWithBundleIconName:name
                          iconFileNames:alt[@"CFBundleIconFiles"]
                          isPrimaryIcon:NO]];
        }
    }

    self.icons = items;
    [self.appIconCollectionView reloadData];
}

// The picker thumbnails live in the asset catalog as "<name>-settings"; the
// primary icon uses the "Icon-<Name>-settings" convention instead. Both fall
// back to the icon art itself if a dedicated thumbnail is missing.
- (UIImage *)thumbnailForItem:(BHAppIconItem *)item {
    UITraitCollection *tc = self.traitCollection;
    NSBundle *bundle = [NSBundle mainBundle];

    NSString *settingsName;
    if (item.isPrimaryIcon) {
        NSString *base = item.bundleIconName;
        if ([base hasSuffix:@"AppIcon"]) {
            base = [base substringToIndex:base.length - @"AppIcon".length];
        }
        settingsName = [NSString stringWithFormat:@"Icon-%@-settings", base];
    } else {
        settingsName = [item.bundleIconName stringByAppendingString:@"-settings"];
    }

    UIImage *img = [UIImage imageNamed:settingsName inBundle:bundle compatibleWithTraitCollection:tc];
    if (!img && item.bundleIconName) {
        img = [UIImage imageNamed:item.bundleIconName inBundle:bundle compatibleWithTraitCollection:tc];
    }
    if (!img) {
        for (NSString *file in [item.bundleIconFiles reverseObjectEnumerator]) {
            img = [UIImage imageNamed:file inBundle:bundle compatibleWithTraitCollection:tc];
            if (img) break;
        }
    }
    return img;
}

- (BOOL)isItemActive:(BHAppIconItem *)item {
    NSString *current = [UIApplication sharedApplication].alternateIconName;
    return item.isPrimaryIcon ? (current == nil)
                              : [current isEqualToString:item.bundleIconName];
}

#pragma mark – UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)cv {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    return self.icons.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    BHAppIconCell *cell = [cv dequeueReusableCellWithReuseIdentifier:[BHAppIconCell reuseIdentifier] forIndexPath:ip];
    BHAppIconItem *item = self.icons[ip.row];

    cell.imageView.image = [self thumbnailForItem:item];

    if (!cell.backgroundView) {
        UIView *shadowView = [[UIView alloc] init];
        shadowView.backgroundColor = [UIColor clearColor];
        shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        shadowView.layer.shadowOffset = CGSizeMake(0, 4);
        shadowView.layer.shadowOpacity = 0.15;
        shadowView.layer.shadowRadius = 8;
        shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 98, 98) cornerRadius:22].CGPath;
        cell.backgroundView = shadowView;
    }

    cell.imageView.layer.cornerRadius = 22;
    cell.imageView.clipsToBounds = YES;

    cell.checkIMG.image = [self isItemActive:item]
        ? [UIImage systemImageNamed:@"checkmark.circle"]
        : [UIImage systemImageNamed:@"circle"];

    return cell;
}

#pragma mark – UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    if (![UIApplication sharedApplication].supportsAlternateIcons) return;

    BHAppIconItem *item = self.icons[ip.row];
    if ([self isItemActive:item]) return;

    NSString *toSet = item.isPrimaryIcon ? nil : item.bundleIconName;

    [[UIApplication sharedApplication] setAlternateIconName:toSet completionHandler:^(NSError *_Nullable error) {
        if (error) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [cv reloadData];
        });
    }];
}

#pragma mark – Section Header

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)ip {
    UICollectionReusableView *header = [cv dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:ip];
    [header.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UILabel *detail = [UILabel new];
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    detail.font = [TwitterChirpFont(TwitterFontStyleRegular) fontWithSize:13];
    detail.textColor = [UIColor secondaryLabelColor];
    detail.numberOfLines = 0;
    detail.textAlignment = NSTextAlignmentLeft;
    detail.text = [[BHTBundle sharedBundle] localizedStringForKey:@"APP_ICON_HEADER_TITLE"];
    [header addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
      [detail.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:16],
      [detail.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-16],
      [detail.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],
      [detail.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-8]
    ]];

    return header;
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)layout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(cv.bounds.size.width, 60);
}

#pragma mark – FlowLayout sizing

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(98, 136);
}

@end
