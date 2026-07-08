//
//  ModernSettingsPageViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/ModernSettingsPageViewController.h"
#import "Settings/ModernSettingsCells.h"
#import "Headers/TWHeaders.h"
#import "Core/BHTManager.h"
#import "Core/BHTBundle.h"
#import "ThemeColor/BHDimPalette.h"

@implementation ModernSettingsPageViewController

- (instancetype)initWithAccount:(TFNTwitterAccount *)account {
    if ((self = [super init])) {
        self.account = account;
        [self buildSettingsList];
        [self updateVisibleToggles];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNav];
    [self setupTable];
}

- (NSString *)pageTitleKey {
    return nil;
}

- (NSString *)pageSubtitleKey {
    return nil;
}

- (void)buildSettingsList {
}

- (void)setupNav {
    NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:[self pageTitleKey]];
    if (self.account) {
        self.navigationItem.titleView = [objc_getClass("TFNTitleView") titleViewWithTitle:title subtitle:self.account.displayUsername];
    } else {
        self.title = title;
    }
}

- (void)setupTable {
    self.view.backgroundColor = [BHDimPalette currentBackgroundColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [BHDimPalette currentBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 80;
    [self.tableView registerClass:[ModernSettingsToggleCell class] forCellReuseIdentifier:@"ToggleCell"];
    [self.tableView registerClass:[ModernSettingsTableViewCell class] forCellReuseIdentifier:@"ButtonCell"];
    [self.tableView registerClass:[ModernSettingsCompactButtonCell class] forCellReuseIdentifier:@"CompactButtonCell"];
    [self.view addSubview:self.tableView];
}

- (void)updateVisibleToggles {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *visible = [NSMutableArray array];
    for (NSDictionary *toggleData in self.toggles) {
        NSString *parentKey = toggleData[@"parentKey"];
        if (parentKey) {
            BOOL parentEnabled = [[defaults objectForKey:parentKey] ?: toggleData[@"default"] boolValue];
            if (parentEnabled) {
                [visible addObject:toggleData];
            }
        } else {
            [visible addObject:toggleData];
        }
    }
    self.visibleToggles = [visible copy];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.visibleToggles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *toggleData = self.visibleToggles[indexPath.row];
    NSString *type = toggleData[@"type"];
    if ([type isEqualToString:@"compactButton"]) {
        ModernSettingsCompactButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CompactButtonCell" forIndexPath:indexPath];
        NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:toggleData[@"titleKey"]];
        NSString *subtitle = @"";
        NSString *prefKey = toggleData[@"prefKeyForSubtitle"];
        if (prefKey) {
            subtitle = [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ?: toggleData[@"subtitleDefault"];
            if ([toggleData[@"isSecure"] boolValue] && subtitle.length > 0 && ![subtitle isEqualToString:toggleData[@"subtitleDefault"]]) {
                subtitle = @"••••••••••••••••";
            }
        }
        [cell configureWithTitle:title subtitle:subtitle];
        return cell;
    } else if ([type isEqualToString:@"button"]) {
        ModernSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
        NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:toggleData[@"titleKey"]];
        NSString *subtitle = @"";
        NSString *prefKey = toggleData[@"prefKeyForSubtitle"];
        if (prefKey) {
            subtitle = [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ?: toggleData[@"subtitleDefault"];
            if ([toggleData[@"isSecure"] boolValue] && subtitle.length > 0 && ![subtitle isEqualToString:toggleData[@"subtitleDefault"]]) {
                subtitle = @"••••••••••••••••";
            }
        }
        NSString *iconName = toggleData[@"icon"];
        [cell configureWithTitle:title subtitle:subtitle iconName:iconName];
        return cell;
    } else {
        ModernSettingsToggleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ToggleCell" forIndexPath:indexPath];
        NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:toggleData[@"titleKey"]];
        NSString *subtitleKey = toggleData[@"subtitleKey"];
        NSString *subtitle = (subtitleKey.length > 0) ? [[BHTBundle sharedBundle] localizedStringForKey:subtitleKey] : @"";
        [cell configureWithTitle:title subtitle:subtitle];
        NSString *key = toggleData[@"key"];
        BOOL isEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:key] ?: toggleData[@"default"] boolValue];
        cell.toggleSwitch.on = isEnabled;
        objc_setAssociatedObject(cell.toggleSwitch, @"prefKey", key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [cell addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *data = self.visibleToggles[indexPath.row];
    if ([data[@"type"] isEqualToString:@"button"] || [data[@"type"] isEqualToString:@"compactButton"]) {
        NSString *actionName = data[@"action"];
        if (actionName) {
            SEL action = NSSelectorFromString(actionName);
            if ([self respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:action withObject:data];
#pragma clang diagnostic pop
            }
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = [[BHTBundle sharedBundle] localizedStringForKey:[self pageSubtitleKey]];
    label.numberOfLines = 0;
    id fontGroup = [BHTManager sharedFontGroup];
    label.font = [fontGroup performSelector:@selector(subtext2Font)];
    Class TAEColorSettingsCls = objc_getClass("TAEColorSettings");
    id settings = [TAEColorSettingsCls sharedSettings];
    id colorPalette = [[settings currentColorPalette] colorPalette];
    UIColor *subtitleColor = [colorPalette performSelector:@selector(tabBarItemColor)];
    label.textColor = subtitleColor;
    [header addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [label.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [label.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],
        [label.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-8]
    ]];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if (key) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:key];
    }
}

@end
