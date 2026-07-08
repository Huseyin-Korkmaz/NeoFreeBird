//
//  WebSettingsViewController.m
//  NeoFreeBird
//
//  Created by nyaathea
//

#import "Settings/Pages/WebSettingsViewController.h"
#import "Settings/ModernSettingsCells.h"
#import "Headers/TWHeaders.h"

@implementation WebSettingsViewController

- (NSString *)pageKey {
    return @"web";
}

- (NSInteger)indexForToggleKey:(NSString *)key inArray:(NSArray<NSDictionary *> *)array {
    __block NSInteger foundIndex = NSNotFound;
    [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if ([obj[@"key"] isEqualToString:key]) {
            foundIndex = (NSInteger)idx;
            *stop = YES;
        }
    }];
    return foundIndex;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *toggleData = self.visibleToggles[indexPath.row];

    // Attach modern URL host menu for this specific row on iOS 14+.
    if (@available(iOS 14.0, *)) {
        if ([toggleData[@"key"] isEqualToString:@"url_host_button"]) {
            [self configureURLHostMenuForCell:(ModernSettingsCompactButtonCell *)cell atIndexPath:indexPath];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *data = self.visibleToggles[indexPath.row];

    // For the URL host row on iOS 14+, the cell itself shows the menu.
    if (@available(iOS 14.0, *)) {
        if ([data[@"key"] isEqualToString:@"url_host_button"]) {
            return;
        }
    }

    if ([data[@"type"] isEqualToString:@"button"] || [data[@"type"] isEqualToString:@"compactButton"]) {
        NSString *actionName = data[@"action"];
        if (actionName) {
            SEL action = NSSelectorFromString(actionName);
            if ([self respondsToSelector:action]) {
                NSMutableDictionary *payload = [data mutableCopy];
                payload[@"indexPath"] = indexPath;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:action withObject:payload];
#pragma clang diagnostic pop
            }
        }
    }
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *key = objc_getAssociatedObject(sender, @"prefKey");
    if (!key) {
        return;
    }

    BOOL isOn = sender.isOn;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isOn forKey:key];
    [defaults synchronize];

    if ([key isEqualToString:@"strip_tracking_params"]) {
        // Find where the domain selector row was and will be
        NSInteger oldIndex = [self indexForToggleKey:@"url_host_button" inArray:self.visibleToggles];

        // Update the data model
        [self updateVisibleToggles];

        NSInteger newIndex = [self indexForToggleKey:@"url_host_button" inArray:self.visibleToggles];

        [self.tableView beginUpdates];

        if (oldIndex == NSNotFound && newIndex != NSNotFound) {
            // Row appeared
            NSIndexPath *ip = [NSIndexPath indexPathForRow:newIndex inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (oldIndex != NSNotFound && newIndex == NSNotFound) {
            // Row disappeared
            NSIndexPath *ip = [NSIndexPath indexPathForRow:oldIndex inSection:0];
            [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

        [self.tableView endUpdates];
    }

    if ([key isEqualToString:@"flex_twitter"]) {
        if (isOn) {
            [[objc_getClass("FLEXManager") sharedManager] showExplorer];
        } else {
            [[objc_getClass("FLEXManager") sharedManager] hideExplorer];
        }
    }
}

- (void)configureURLHostMenuForCell:(ModernSettingsCompactButtonCell *)cell
                        atIndexPath:(NSIndexPath *)indexPath {
    if (!cell) {
        return;
    }

    if (!@available(iOS 14.0, *)) {
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentHost = [defaults objectForKey:@"tweet_url_host"] ?: @"x.com";

    NSArray<NSString *> *hosts = @[
        @"x.com",
        @"twitter.com",
        @"fxtwitter.com",
        @"vxtwitter.com",
        @"fixvx.com"
    ];

    // Create or reuse a button that will host the menu.
    UIButton *menuButton = [cell.contentView viewWithTag:4242];
    if (!menuButton) {
        menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
        menuButton.tag = 4242;
        menuButton.backgroundColor = [UIColor clearColor];
        // No title or image, purely functional.
        [cell.contentView addSubview:menuButton];
    }

    // Place the button over the right half of the cell so the menu anchor
    // is near the domain text instead of the center of the cell.
    CGFloat width = cell.contentView.bounds.size.width;
    CGFloat height = cell.contentView.bounds.size.height;
    CGFloat buttonWidth = width * 0.5; // right half
    menuButton.frame = CGRectMake(width - buttonWidth, 0.0, buttonWidth, height);
    menuButton.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleLeftMargin;
    [cell.contentView bringSubviewToFront:menuButton];

    NSMutableArray<UIAction *> *actions = [NSMutableArray array];

    for (NSString *host in hosts) {
        UIAction *action = [UIAction actionWithTitle:host
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull a) {
            [defaults setObject:host forKey:@"tweet_url_host"];
            [defaults synchronize];

            if (indexPath) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        }];

        if ([host isEqualToString:currentHost]) {
            action.state = UIMenuElementStateOn;
        }

        [actions addObject:action];
    }

    UIMenu *menu = [UIMenu menuWithTitle:@"URL"
                                   image:nil
                              identifier:nil
                                 options:0
                                children:actions];

    menuButton.menu = menu;
    menuButton.showsMenuAsPrimaryAction = YES;
}

@end
