//
//  Misc.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Always open in Safari

// In-app browser is used for two-factor authentication with security key,
// login will not complete successfully if it's redirected to Safari
static BOOL BHTShouldKeepBrowserURLInApp(NSURL *url) {
    NSString *urlStr = [url absoluteString];

    return [urlStr containsString:@"twitter.com/account/"] || [urlStr containsString:@"twitter.com/i/flow/"] ||
           [urlStr containsString:@"x.com/account/"] || [urlStr containsString:@"x.com/i/flow/"];
}

// Every tapped link that resolves to the in-app Safari goes through this single
// present funnel, so diverting here avoids presenting anything at all.
%hook T1SafariViewController

- (void)tfnPresentedCustomPresentFromViewController:(UIViewController *)fromViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    if (![BHTSettings boolForKey:@"always_open_safari"]) {
        return %orig;
    }

    NSURL *url = [self rootURL] ?: [self initialURL];
    if (url == nil || BHTShouldKeepBrowserURLInApp(url)) {
        return %orig;
    }

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];

    if (completion) {
        completion();
    }
}

%end

// Fallback for the plain SFSafariViewController surfaces (help pages, Grok,
// XLinkWebView), which don't go through the T1SafariViewController funnel.
%hook SFSafariViewController

- (void)viewWillAppear:(BOOL)animated {
    if (![BHTSettings boolForKey:@"always_open_safari"]) {
        return %orig;
    }

    NSURL *url = [self initialURL];
    if (url == nil || BHTShouldKeepBrowserURLInApp(url)) {
        return %orig;
    }

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

%end

// MARK: Expand t.co links

%hook TFSTwitterEntityURL

- (NSString *)url {
    // The entity is also used for URLs that never had a t.co wrapper (e.g.
    // share links), where expandedURL is nil.
    NSString *expandedURL = self.expandedURL;
    return expandedURL ?: %orig;
}

%end

// MARK: Disable RTL

// Tweet text is rendered with CoreText, which resolves the writing direction
// from the first strong directional character. Forcing LTR on the paragraph
// style of the render input is the only reliable override.
%hook TFNAttributedTextModel

- (void)setAttributedString:(NSAttributedString *)attributedString {
    if (![BHTSettings boolForKey:@"disable_rtl"] || attributedString.length == 0) {
        return %orig;
    }

    NSMutableAttributedString *text = [attributedString mutableCopy];
    [text enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, text.length) options:0 usingBlock:^(NSParagraphStyle *value, NSRange range, BOOL *stop) {
        NSMutableParagraphStyle *style = value ? [value mutableCopy] : [NSMutableParagraphStyle new];
        style.baseWritingDirection = NSWritingDirectionLeftToRight;
        [text addAttribute:NSParagraphStyleAttributeName value:style range:range];
    }];

    %orig(text);
}

%end

// MARK: Show Scroll Bar

%hook TFNTableView

- (void)setShowsVerticalScrollIndicator:(BOOL)arg1 {
    %orig([BHTSettings boolForKey:@"show_scroll_indicator"]);
}

%end

// MARK: Strip tracking params from shared links

// The ?s= source param is baked into the share URL format strings, and the
// &t= session token is appended by _t1_transformShareURL: (disabled at the
// source via the rehire_share_update_url_enabled switch in FeatureSwitches.x).
static NSString *BHTCleanedShareURLString(NSString *urlString) {
    if (urlString == nil) {
        return urlString;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    if (components == nil) {
        return urlString;
    }

    NSMutableArray<NSURLQueryItem *> *safeParams = [NSMutableArray arrayWithCapacity:0];
    for (NSURLQueryItem *item in components.queryItems) {
        if (![item.name isEqualToString:@"s"] && ![item.name isEqualToString:@"t"]) {
            [safeParams addObject:item];
        }
    }
    components.queryItems = safeParams.count > 0 ? safeParams : nil;

    NSString *selectedHost = [[NSUserDefaults standardUserDefaults] objectForKey:@"sharing_domain"];
    if (selectedHost.length > 0) {
        components.host = selectedHost;
    }

    return components.URL.absoluteString ?: urlString;
}

// Every share surface (copy link, share sheet, DM, email, Snap) funnels into
// these two builders; the legacy twitterURLFor* selectors wrap the instance
// one, and the Swift share kit calls it directly with its own s value.
%hook TFNTwitterStatus

- (NSString *)twitterURLForShareWithSParam:(unsigned int)sParam {
    NSString *url = %orig;
    return BHTCleanedShareURLString(url);
}

+ (NSString *)twitterURLForShareWithSParam:(unsigned int)sParam username:(NSString *)username statusID:(long long)statusID {
    NSString *url = %orig;
    return BHTCleanedShareURLString(url);
}

%end

// Profile links
%hook TFSTwitterUserReference

- (NSString *)twitterURLForShare {
    NSString *url = %orig;
    return BHTCleanedShareURLString(url);
}

- (NSString *)twitterURLForCopy {
    NSString *url = %orig;
    return BHTCleanedShareURLString(url);
}

%end
