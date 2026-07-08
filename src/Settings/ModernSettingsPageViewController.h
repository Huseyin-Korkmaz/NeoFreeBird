//
//  ModernSettingsPageViewController.h
//  NeoFreeBird
//
//  Created by nyaathea
//

#import <UIKit/UIKit.h>

@class TFNTwitterAccount;

@interface ModernSettingsPageViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) TFNTwitterAccount *account;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *toggles;
@property (nonatomic, strong) NSArray<NSDictionary *> *visibleToggles;

- (instancetype)initWithAccount:(TFNTwitterAccount *)account;

// Overridden by each page to identify its entry in the BHTSettings registry
- (NSString *)pageKey;

- (NSString *)pageTitleKey;
- (NSString *)pageSubtitleKey;
- (void)buildSettingsList;

- (void)updateVisibleToggles;
- (void)switchChanged:(UISwitch *)sender;

@end
