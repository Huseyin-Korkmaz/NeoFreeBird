//
//  Profile.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// Declare Twitter's vector loader.
@interface UIImage (TwitterVectors)
+ (UIImage *)tfn_vectorImageNamed:(NSString *)name
                         fitsSize:(CGSize)size
                        fillColor:(UIColor *)fillColor;
@end

static inline UIImage *BHTVectorIcon(NSString *name, CGFloat size) {
    if (!name.length) return nil;
    return [UIImage tfn_vectorImageNamed:name
                                fitsSize:CGSizeMake(size, size)
                               fillColor:UIColor.labelColor];
}

static inline NSString *BHTIconNameForKey(NSString *key) {
    if ([key isEqualToString:@"button"])   return @"copy_stroke";
    if ([key isEqualToString:@"bio"])      return @"news_stroke";
    if ([key isEqualToString:@"username"]) return @"at";
    if ([key isEqualToString:@"fullname"]) return @"account";
    if ([key isEqualToString:@"url"])      return @"link";
    if ([key isEqualToString:@"location"]) return @"location_stroke";
    return @"copy_stroke";
}

#pragma mark - Theme detection and style helpers

typedef NS_ENUM(NSInteger, BHTTwitterThemeVariant) {
    BHTTwitterThemeVariantLight = 0,
    BHTTwitterThemeVariantDim   = 1,
    BHTTwitterThemeVariantBlack = 2, // Lights out / pure black
};

// Decide between Light / Dim / Lights out using BHDimPalette for dim.
static BHTTwitterThemeVariant BHTCurrentTwitterThemeVariant(T1ProfileHeaderView *headerView) {
    UIUserInterfaceStyle style = UIUserInterfaceStyleLight;

    if (headerView) {
        if (@available(iOS 13.0, *)) {
            style = headerView.traitCollection.userInterfaceStyle;
        }
    }

    // System / Twitter light theme
    if (style == UIUserInterfaceStyleLight) {
        return BHTTwitterThemeVariantLight;
    }

    // Dark family: use BHDimPalette to distinguish Dim from Lights out.
    if ([BHDimPalette isDimMode]) {
        return BHTTwitterThemeVariantDim;
    }

    // Dark but not dim -> Lights out (black).
    return BHTTwitterThemeVariantBlack;
}

// Style using the logged RGBA values for each theme.
static void BHTApplyCopyButtonStyle(UIButton *copyButton, T1ProfileHeaderView *headerView) {
    if (!copyButton) return;

    BHTTwitterThemeVariant variant = BHTCurrentTwitterThemeVariant(headerView);

    copyButton.layer.cornerRadius = 16.0;
    copyButton.layer.masksToBounds = YES;
    copyButton.layer.borderWidth = 1.0;
    copyButton.backgroundColor = nil;

    switch (variant) {
        case BHTTwitterThemeVariantLight: {
            // Light mode logs:
            // tint:   0.000 0.533 1.000
            // border: 0.812 0.851 0.871
            copyButton.tintColor = [UIColor colorWithRed:0.000f
                                                   green:0.533f
                                                    blue:1.000f
                                                   alpha:1.0f];
            copyButton.layer.borderColor = [UIColor colorWithRed:0.812f
                                                           green:0.851f
                                                            blue:0.871f
                                                           alpha:1.0f].CGColor;
            break;
        }

        case BHTTwitterThemeVariantDim: {
            // Dim mode logs:
            // tint:   0.000 0.569 1.000
            // border: 0.259 0.325 0.392
            copyButton.tintColor = [UIColor colorWithRed:0.000f
                                                   green:0.569f
                                                    blue:1.000f
                                                   alpha:1.0f];
            copyButton.layer.borderColor = [UIColor colorWithRed:0.259f
                                                           green:0.325f
                                                            blue:0.392f
                                                           alpha:1.0f].CGColor;
            break;
        }

        case BHTTwitterThemeVariantBlack: {
            // Lights out logs:
            // tint:   0.000 0.569 1.000
            // border: 0.200 0.212 0.224
            copyButton.tintColor = [UIColor colorWithRed:0.000f
                                                   green:0.569f
                                                    blue:1.000f
                                                   alpha:1.0f];
            copyButton.layer.borderColor = [UIColor colorWithRed:0.200f
                                                           green:0.212f
                                                            blue:0.224f
                                                           alpha:1.0f].CGColor;
            break;
        }
    }
}

#pragma mark - Hook

%hook T1ProfileHeaderViewController

- (void)viewDidAppear:(_Bool)arg1 {
    %orig(arg1);

    if (![BHTSettings boolForKey:@"copy_profile_info"]) {
        return;
    }

    T1ProfileHeaderView *headerView = [self valueForKey:@"_headerView"];
    if (!headerView || ![headerView respondsToSelector:@selector(actionButtonsView)]) {
        return;
    }

    UIView *actionButtonsView = headerView.actionButtonsView;
    UIView *innerContentView = [actionButtonsView valueForKey:@"_innerContentView"];
    if (!innerContentView) innerContentView = actionButtonsView;

    // Reuse if it already exists.
    UIButton *copyButton = (UIButton *)[actionButtonsView viewWithTag:9001];
    if (!copyButton) {
        copyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [copyButton setImage:BHTVectorIcon(BHTIconNameForKey(@"button"), 18.0)
                    forState:UIControlStateNormal];
        copyButton.tag = 9001;

        if (@available(iOS 14.0, *)) {
            [copyButton setShowsMenuAsPrimaryAction:true];

            UIAction *fullname = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_3"]
                                                     image:BHTVectorIcon(BHTIconNameForKey(@"fullname"), 16.0)
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
                if (self.viewModel.fullName != nil) UIPasteboard.generalPasteboard.string = self.viewModel.fullName;
            }];

            UIAction *username = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_2"]
                                                     image:BHTVectorIcon(BHTIconNameForKey(@"username"), 16.0)
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
                if (self.viewModel.username != nil) UIPasteboard.generalPasteboard.string = self.viewModel.username;
            }];

            UIAction *bio = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_1"]
                                                image:BHTVectorIcon(BHTIconNameForKey(@"bio"), 16.0)
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
                if (self.viewModel.bio != nil) UIPasteboard.generalPasteboard.string = self.viewModel.bio;
            }];

            UIAction *location = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_5"]
                                                     image:BHTVectorIcon(BHTIconNameForKey(@"location"), 16.0)
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
                if (self.viewModel.location != nil) UIPasteboard.generalPasteboard.string = self.viewModel.location;
            }];

            UIAction *url = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_4"]
                                                image:BHTVectorIcon(BHTIconNameForKey(@"url"), 16.0)
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
                if (self.viewModel.url != nil) UIPasteboard.generalPasteboard.string = self.viewModel.url;
            }];

            [copyButton setMenu:[UIMenu menuWithTitle:@"" children:@[fullname, username, bio, location, url]]];
        } else {
            [copyButton addTarget:self
                           action:@selector(copyButtonHandler:)
                 forControlEvents:UIControlEventTouchUpInside];
        }

        copyButton.translatesAutoresizingMaskIntoConstraints = NO;
        [actionButtonsView addSubview:copyButton];

        [NSLayoutConstraint activateConstraints:@[
            [copyButton.centerYAnchor constraintEqualToAnchor:actionButtonsView.centerYAnchor],
            [copyButton.widthAnchor constraintEqualToConstant:32.0],
            [copyButton.heightAnchor constraintEqualToConstant:32.0],
        ]];

        if (isDeviceLanguageRTL()) {
            [NSLayoutConstraint activateConstraints:@[
                [copyButton.leadingAnchor constraintEqualToAnchor:innerContentView.trailingAnchor constant:7.0],
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[
                [copyButton.trailingAnchor constraintEqualToAnchor:innerContentView.leadingAnchor constant:-7.0],
            ]];
        }
    } else {
        [copyButton setImage:BHTVectorIcon(BHTIconNameForKey(@"button"), 18.0)
                    forState:UIControlStateNormal];
    }

    // Style for current theme.
    BHTApplyCopyButtonStyle(copyButton, headerView);
}

%new - (void)copyButtonHandler:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    if (is_iPad()) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = sender.frame;
    }

    UIAlertAction *fullname = [UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_3"]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        if (self.viewModel.fullName != nil) UIPasteboard.generalPasteboard.string = self.viewModel.fullName;
    }];

    UIAlertAction *username = [UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_2"]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        if (self.viewModel.username != nil) UIPasteboard.generalPasteboard.string = self.viewModel.username;
    }];

    UIAlertAction *bio = [UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_1"]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
        if (self.viewModel.bio != nil) UIPasteboard.generalPasteboard.string = self.viewModel.bio;
    }];

    UIAlertAction *location = [UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_5"]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        if (self.viewModel.location != nil) UIPasteboard.generalPasteboard.string = self.viewModel.location;
    }];

    UIAlertAction *url = [UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_4"]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
        if (self.viewModel.url != nil) UIPasteboard.generalPasteboard.string = self.viewModel.url;
    }];

    if (@available(iOS 13.0, *)) {
        [bio setValue:BHTVectorIcon(BHTIconNameForKey(@"bio"), 16.0) forKey:@"image"];
        [username setValue:BHTVectorIcon(BHTIconNameForKey(@"username"), 16.0) forKey:@"image"];
        [fullname setValue:BHTVectorIcon(BHTIconNameForKey(@"fullname"), 16.0) forKey:@"image"];
        [url setValue:BHTVectorIcon(BHTIconNameForKey(@"url"), 16.0) forKey:@"image"];
        [location setValue:BHTVectorIcon(BHTIconNameForKey(@"location"), 16.0) forKey:@"image"];
    }

    [alert addAction:fullname];
    [alert addAction:username];
    [alert addAction:bio];
    [alert addAction:location];
    [alert addAction:url];
    [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"CANCEL_BUTTON_TITLE"]
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:true completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);

    if (![BHTSettings boolForKey:@"copy_profile_info"]) {
        return;
    }

    T1ProfileHeaderView *headerView = [self valueForKey:@"_headerView"];
    if (!headerView || ![headerView respondsToSelector:@selector(actionButtonsView)]) {
        return;
    }

    UIButton *copyButton = (UIButton *)[headerView.actionButtonsView viewWithTag:9001];
    if (!copyButton) {
        return;
    }

    [copyButton setImage:BHTVectorIcon(BHTIconNameForKey(@"button"), 18.0)
                forState:UIControlStateNormal];

    if (@available(iOS 14.0, *)) {
        UIAction *fullname = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_3"]
                                                 image:BHTVectorIcon(BHTIconNameForKey(@"fullname"), 16.0)
                                            identifier:nil
                                               handler:^(__kindof UIAction * _Nonnull action) {
            if (self.viewModel.fullName != nil) UIPasteboard.generalPasteboard.string = self.viewModel.fullName;
        }];
        UIAction *username = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_2"]
                                                 image:BHTVectorIcon(BHTIconNameForKey(@"username"), 16.0)
                                            identifier:nil
                                               handler:^(__kindof UIAction * _Nonnull action) {
            if (self.viewModel.username != nil) UIPasteboard.generalPasteboard.string = self.viewModel.username;
        }];
        UIAction *bio = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_1"]
                                            image:BHTVectorIcon(BHTIconNameForKey(@"bio"), 16.0)
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
            if (self.viewModel.bio != nil) UIPasteboard.generalPasteboard.string = self.viewModel.bio;
        }];
        UIAction *location = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_5"]
                                                 image:BHTVectorIcon(BHTIconNameForKey(@"location"), 16.0)
                                            identifier:nil
                                               handler:^(__kindof UIAction * _Nonnull action) {
            if (self.viewModel.location != nil) UIPasteboard.generalPasteboard.string = self.viewModel.location;
        }];
        UIAction *url = [UIAction actionWithTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"COPY_PROFILE_INFO_MENU_OPTION_4"]
                                            image:BHTVectorIcon(BHTIconNameForKey(@"url"), 16.0)
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
            if (self.viewModel.url != nil) UIPasteboard.generalPasteboard.string = self.viewModel.url;
        }];
        [copyButton setMenu:[UIMenu menuWithTitle:@"" children:@[fullname, username, bio, location, url]]];
    }

    // Reapply style so border/tint match the updated theme.
    BHTApplyCopyButtonStyle(copyButton, headerView);
}

%end

%hook T1ProfileSummaryView
- (BOOL)shouldShowGetVerifiedButton {
    return [BHTSettings boolForKey:@"hide_premium_offer"] ? false : %orig;
}
%end

// MARK: Show unrounded follower/following counts
%hook T1ProfileFriendsFollowingViewModel
- (id)_t1_followCountTextWithLabel:(id)label singularLabel:(id)singularLabel count:(id)count highlighted:(_Bool)highlighted {
    // First get the original result to understand the expected return type
    id originalResult = %orig;

    // Only proceed if we have a valid count that's an NSNumber
    if (count && [count isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)count;

        // Only show full numbers for counts under 10,000
        if ([number integerValue] >= 10000) {
            return originalResult;
        }

        // Format the number with the current locale's formatting
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setUsesGroupingSeparator:YES];
        NSString *formattedCount = [formatter stringFromNumber:number];

        // If original result is an NSString, find and replace abbreviated numbers
        if ([originalResult isKindOfClass:[NSString class]]) {
            NSString *originalString = (NSString *)originalResult;
            // Updated regex to match patterns like "1.7K", "1,7K", "6.2K", "6,2K", etc.
            // This handles both period and comma as decimal separators
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+[.,]\\d+[KMB]|\\d+[KMB]" options:0 error:nil];
            NSString *result = [regex stringByReplacingMatchesInString:originalString options:0 range:NSMakeRange(0, originalString.length) withTemplate:formattedCount];
            return result;
        }
        // If original result is an NSAttributedString, modify that
        else if ([originalResult isKindOfClass:[NSAttributedString class]]) {
            NSMutableAttributedString *mutableResult = [[NSMutableAttributedString alloc] initWithAttributedString:(NSAttributedString *)originalResult];
            NSString *originalText = mutableResult.string;

            // Updated regex to match patterns like "1.7K", "1,7K", "6.2K", "6,2K", etc.
            // This handles both period and comma as decimal separators
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+[.,]\\d+[KMB]|\\d+[KMB]" options:0 error:nil];
            NSArray *matches = [regex matchesInString:originalText options:0 range:NSMakeRange(0, originalText.length)];

            // Replace matches in reverse order to maintain correct indices
            for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
                [mutableResult replaceCharactersInRange:match.range withString:formattedCount];
            }
            return [mutableResult copy];
        }
    }
    return originalResult;
}
%end
@class T1ProfileHeaderViewController; // Forward declaration instead of interface definition

// It's good practice to also declare the class we are looking for, even if just minimally
@interface T1SuperFollowControl : UIView
@property(retain, nonatomic) UIButton *button;
@end
%hook T1SuperFollowControl

- (id)initWithSizeClass:(long long)arg1 {
    id result = %orig;
    if ([BHTSettings boolForKey:@"restore_follow_button"] && result) {
        [self setHidden:YES];
        [self setAlpha:0.0];
    }
    return result;
}

- (void)_t1_configureButton {
    %orig;
    if ([BHTSettings boolForKey:@"restore_follow_button"]) {
        [self setHidden:YES];
        [self setAlpha:0.0];
        if (self.button) {
            [self.button setHidden:YES];
            [self.button setAlpha:0.0];
        }
    }
}
%end

// MARK : fix for super follower profiles.
%hook T1ProfileActionButtonsView

// Method that creates the overflow button
- (id)_t1_overflowButtonForItems:(id)arg1 {
    if ([BHTSettings boolForKey:@"restore_follow_button"]) {
        return nil; // Return nil to prevent the overflow button from appearing
    }
    return %orig;
}

// Override the method that determines which buttons to show based on width
- (void)_t1_updateArrangedButtonItemsForContentWidth:(double)arg1 {
    if ([BHTSettings boolForKey:@"restore_follow_button"]) {
        %orig(10000.0);
    } else {
        %orig(arg1);
    }
}

%end
