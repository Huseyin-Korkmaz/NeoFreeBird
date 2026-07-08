//
//  Misc.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static id _PasteboardChangeObserver;
static NSDictionary<NSString*, NSArray<NSString*>*> *trackingParams;
static NSString *_lastCopiedURL;

// MARK: Always open in Safari

%hook SFSafariViewController
- (void)viewWillAppear:(BOOL)animated {
    if (![BHTManager alwaysOpenSafari]) {
        return %orig;
    }

    NSURL *url = [self initialURL];
    NSString *urlStr = [url absoluteString];

    // In-app browser is used for two-factor authentication with security key,
    // login will not complete successfully if it's redirected to Safari
    if ([urlStr containsString:@"twitter.com/account/"] || [urlStr containsString:@"twitter.com/i/flow/"]) {
        return %orig;
    }

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (instancetype)initWithURL:(NSURL *)URL configuration:(SFSafariViewControllerConfiguration *)configuration {
    if (![BHTManager alwaysOpenSafari]) {
        return %orig;
    }

    NSString *urlStr = [URL absoluteString];

    // In-app browser is used for two-factor authentication with security key,
    // login will not complete successfully if it's redirected to Safari
    if ([urlStr containsString:@"twitter.com/account/"] || [urlStr containsString:@"twitter.com/i/flow/"]) {
        return %orig;
    }

    // Open in Safari instead and return nil to prevent SFSafariViewController creation
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    return nil;
}

- (instancetype)initWithURL:(NSURL *)URL {
    if (![BHTManager alwaysOpenSafari]) {
        return %orig;
    }

    NSString *urlStr = [URL absoluteString];

    // In-app browser is used for two-factor authentication with security key,
    // login will not complete successfully if it's redirected to Safari
    if ([urlStr containsString:@"twitter.com/account/"] || [urlStr containsString:@"twitter.com/i/flow/"]) {
        return %orig;
    }

    // Open in Safari instead and return nil to prevent SFSafariViewController creation
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    return nil;
}
%end

%hook SFInteractiveDismissController
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (![BHTManager alwaysOpenSafari]) {
        return %orig;
    }
    [transitionContext completeTransition:NO];
}
%end

%hook TFSTwitterEntityURL
- (NSString *)url {
    // https://github.com/haoict/twitter-no-ads/blob/master/Tweak.xm#L195
    return self.expandedURL;
}
%end

// MARK: Disable RTL
%hook NSParagraphStyle
+ (NSWritingDirection)defaultWritingDirectionForLanguage:(id)lang {
    return [BHTManager disableRTL] ? NSWritingDirectionLeftToRight : %orig;
}
+ (NSWritingDirection)_defaultWritingDirection {
    return [BHTManager disableRTL] ? NSWritingDirectionLeftToRight : %orig;
}
%end

// MARK: Bio Translate
%hook TFNTwitterCanonicalUser
- (_Bool)isProfileBioTranslatable {
    return [BHTManager BioTranslate] ? true : %orig;
}
%end
// MARK: Show Scroll Bar
%hook TFNTableView
- (void)setShowsVerticalScrollIndicator:(BOOL)arg1 {
    %orig([BHTManager showScrollIndicator]);
}
%end

%ctor {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    // Someone needs to hold reference the to Notification
    _PasteboardChangeObserver = [center addObserverForName:UIPasteboardChangedNotification object:nil queue:mainQueue usingBlock:^(NSNotification * _Nonnull note){

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            trackingParams = @{
                @"twitter.com" : @[@"s", @"t"],
                @"x.com" : @[@"s", @"t"],
            };
        });

        if ([BHTManager stripTrackingParams]) {
            if (UIPasteboard.generalPasteboard.hasURLs) {
                NSURL *pasteboardURL = UIPasteboard.generalPasteboard.URL;
                NSArray<NSString*>* params = trackingParams[pasteboardURL.host];

                if ([pasteboardURL.absoluteString isEqualToString:_lastCopiedURL] == NO && params != nil && pasteboardURL.query != nil) {
                    // to prevent endless copy loop
                    _lastCopiedURL = pasteboardURL.absoluteString;
                    NSURLComponents *cleanedURL = [NSURLComponents componentsWithURL:pasteboardURL resolvingAgainstBaseURL:NO];
                    NSMutableArray<NSURLQueryItem*> *safeParams = [NSMutableArray arrayWithCapacity:0];

                    for (NSURLQueryItem *item in cleanedURL.queryItems) {
                        if ([params containsObject:item.name] == NO) {
                            [safeParams addObject:item];
                        }
                    }
                    cleanedURL.queryItems = safeParams.count > 0 ? safeParams : nil;

                    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"tweet_url_host"]) {
                        NSString *selectedHost = [[NSUserDefaults standardUserDefaults] objectForKey:@"tweet_url_host"];
                        cleanedURL.host = selectedHost;
                    }
                    UIPasteboard.generalPasteboard.URL = cleanedURL.URL;
                }
            }
        }
    }];

    %init;
}
