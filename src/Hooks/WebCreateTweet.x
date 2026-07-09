//
//  WebCreateTweet.x
//  NeoFreeBird
//
//  Reroutes native tweet posting through x.com's web GraphQL CreateTweet endpoint
//  so sideloaded / legacy sessions can post without hitting native attestation.
//
//  The seam is NSURLSession: the native app still issues CreateTweet as an ordinary
//  data/upload task to .../graphql/<queryId>/CreateTweet, so we rewrite that request
//  in flight with web-session auth (auth_token + ct0 cookies + csrf header) and a
//  fresh x-client-transaction-id. We never read the response body, only its status
//  code, so response encoding (gzip) is irrelevant.
//
//  Gated on the inverse of `reply_in_webview`: when that setting is on, WebReply.x
//  handles composing in a webview instead and this interception stays out of the way.
//

#import "BHTHookHelpers.h"

// MARK: - Constants

static NSString *const BHTWebBearer =
    @"Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA";

static NSString *const BHTWebQueryIDDefaultsKey = @"nfb_createtweet_queryid";
static NSString *BHTWebCreateTweetQueryID = @"vwzfnq1lLOa1Nfx7htM2mw";

// MARK: - Session state

// Latest cookies harvested from the app's web session (the account currently signed in
// on the web). auth_multi carries the auth_token of every other signed-in account.
static NSString *BHTWebCT0 = nil;
static NSString *BHTWebAuthToken = nil;
static NSString *BHTWebTwid = nil;
static NSString *BHTWebAuthMulti = nil;

// Per-account resolved credentials (userID -> @{auth_token, ct0, twid}).
static NSMutableDictionary<NSString *, NSDictionary *> *BHTWebAccountCookies = nil;
static NSObject *BHTWebAccountCookiesLock = nil;

// The authenticated helper webview is kept alive so we can mint a fresh
// x-client-transaction-id per send (x rate-limits requests without one).
static WKWebView *BHTWebHelperWebView = nil;
static BOOL BHTWebHelperReady = NO;
static BOOL BHTWebHelperInFlight = NO;
static NSString *BHTWebXTID = nil;
static BOOL BHTWebXTIDInFlight = NO;

// Offscreen native webview used to establish/harvest a specific account's web session.
static UIWindow *BHTWebHarvestWindow = nil;
static BOOL BHTWebBootstrapInFlight = NO;

static const void *BHTWebPostingUIDKey = &BHTWebPostingUIDKey;
static const void *BHTWebHarvestWebViewKey = &BHTWebHarvestWebViewKey;
static const void *BHTCreateTweetWatcherKey = &BHTCreateTweetWatcherKey;

static void BHT_refreshXTID(void);
static void BHT_refreshWebCookiesViaWebView(void);
static void BHT_teardownWebHarvestWindow(void);

@interface WKWebView (BHTAsyncJavaScript)
- (void)callAsyncJavaScript:(NSString *)functionBody
                  arguments:(NSDictionary<NSString *, id> *)arguments
                    inFrame:(WKFrameInfo *)frame
             inContentWorld:(WKContentWorld *)contentWorld
          completionHandler:(void (^)(id result, NSError *error))completionHandler;
@end

static BOOL BHT_nativeCreateTweetInterceptEnabled(void) {
    return ![BHTSettings boolForKey:@"reply_in_webview"];
}

// MARK: - Small helpers

// twid is stored as "u=<id>" (percent-encoded). Pull the numeric account id out of it.
static NSString *BHT_userIDFromTwid(NSString *twid) {
    if (twid.length == 0) {
        return nil;
    }
    NSString *decoded = [twid stringByRemovingPercentEncoding] ?: twid;
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *digits = [[decoded componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    return digits.length ? digits : nil;
}

static NSString *BHT_userIDStringForAccount(id account) {
    if (!account || ![account respondsToSelector:@selector(userID)]) {
        return nil;
    }
    long long uid = ((long long (*)(id, SEL))objc_msgSend)(account, @selector(userID));
    return uid ? [@(uid) stringValue] : nil;
}

static id BHT_accountForUserID(NSString *userID) {
    if (userID.length == 0) {
        return nil;
    }
    @try {
        Class twitterClass = %c(TFNTwitter);
        if (![twitterClass respondsToSelector:@selector(sharedTwitter)]) {
            return nil;
        }
        id twitter = ((id (*)(id, SEL))objc_msgSend)((id)twitterClass, @selector(sharedTwitter));
        if (![twitter respondsToSelector:@selector(accounts)]) {
            return nil;
        }
        NSArray *accounts = ((id (*)(id, SEL))objc_msgSend)(twitter, @selector(accounts));
        for (id account in accounts) {
            if ([BHT_userIDStringForAccount(account) isEqualToString:userID]) {
                return account;
            }
        }
    } @catch (__unused NSException *exception) {}
    return nil;
}

static UIWindowScene *BHT_activeWindowScene(void) {
    UIWindowScene *fallback = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
        if (!fallback) {
            fallback = (UIWindowScene *)scene;
        }
    }
    return fallback;
}

// Runs `ready` in a tight poll off the main thread, kicking `kick` every ~3s, until it
// passes or the deadline elapses. Never blocks the main thread.
static BOOL BHT_waitUntil(BOOL (^ready)(void), void (^kick)(void), NSTimeInterval maxSeconds) {
    if (ready()) {
        return YES;
    }
    if ([NSThread isMainThread]) {
        return NO;
    }

    NSUInteger maxTicks = (NSUInteger)(maxSeconds / 0.05);
    for (NSUInteger tick = 0; tick < maxTicks && !ready(); tick++) {
        if (kick && (tick % 60 == 0)) {
            dispatch_async(dispatch_get_main_queue(), kick);
        }
        [NSThread sleepForTimeInterval:0.05];
    }
    return ready();
}

// MARK: - Cookie harvesting

static NSObject *BHT_accountCacheLock(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BHTWebAccountCookiesLock = [NSObject new];
        BHTWebAccountCookies = [NSMutableDictionary dictionary];
    });
    return BHTWebAccountCookiesLock;
}

static void BHT_cacheAccountPair(NSString *userID, NSDictionary *pair) {
    if (userID.length == 0) {
        return;
    }
    @synchronized (BHT_accountCacheLock()) {
        if (pair) {
            BHTWebAccountCookies[userID] = pair;
        } else {
            [BHTWebAccountCookies removeObjectForKey:userID];
        }
    }
}

static NSDictionary *BHT_cachedAccountPair(NSString *userID) {
    if (userID.length == 0) {
        return nil;
    }
    @synchronized (BHT_accountCacheLock()) {
        return BHTWebAccountCookies[userID];
    }
}

static void BHT_storeWebCookies(NSArray<NSHTTPCookie *> *cookies) {
    if (![cookies isKindOfClass:[NSArray class]]) {
        return;
    }

    for (NSHTTPCookie *cookie in cookies) {
        NSString *domain = cookie.domain ?: @"";
        if (![domain containsString:@"x.com"] && ![domain containsString:@"twitter.com"]) {
            continue;
        }
        if (cookie.value.length == 0) {
            continue;
        }

        if ([cookie.name isEqualToString:@"ct0"]) {
            BHTWebCT0 = [cookie.value copy];
        } else if ([cookie.name isEqualToString:@"auth_token"]) {
            BHTWebAuthToken = [cookie.value copy];
        } else if ([cookie.name isEqualToString:@"twid"]) {
            BHTWebTwid = [cookie.value copy];
        } else if ([cookie.name isEqualToString:@"auth_multi"]) {
            BHTWebAuthMulti = [cookie.value copy];
        }
    }

    NSString *userID = BHT_userIDFromTwid(BHTWebTwid);
    if (userID.length && BHTWebAuthToken.length && BHTWebCT0.length) {
        BHT_cacheAccountPair(userID, @{
            @"auth_token": BHTWebAuthToken,
            @"ct0": BHTWebCT0,
            @"twid": BHTWebTwid,
        });
    }
}

static void BHT_harvestSharedCookies(void) {
    NSMutableArray<NSHTTPCookie *> *all = [NSMutableArray array];
    for (NSString *domain in @[@"https://api.twitter.com", @"https://twitter.com", @"https://x.com"]) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:domain]];
        if (cookies) {
            [all addObjectsFromArray:cookies];
        }
    }
    BHT_storeWebCookies(all);
}

// MARK: - Helper webview (x-client-transaction-id)

static void BHT_onHelperWebViewLoaded(WKWebView *webView);

@interface BHTWebHelperDelegate : NSObject <WKNavigationDelegate>
@end
@implementation BHTWebHelperDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(__unused WKNavigation *)navigation {
    BHT_onHelperWebViewLoaded(webView);
}
- (void)webView:(__unused WKWebView *)webView didFailProvisionalNavigation:(__unused WKNavigation *)navigation withError:(__unused NSError *)error {
    BHTWebHelperWebView = nil;
    BHTWebHelperReady = NO;
    BHTWebHelperInFlight = NO;
}
@end

static BHTWebHelperDelegate *BHTWebHelperDelegateInstance = nil;

// Seed the helper webview's cookie store with the harvested session cookies so it loads
// authenticated.
static void BHT_seedHelperCookies(WKWebView *webView, void (^done)(void)) {
    NSDictionary *pairs = @{ @"auth_token": BHTWebAuthToken ?: @"",
                             @"ct0": BHTWebCT0 ?: @"",
                             @"twid": BHTWebTwid ?: @"" };

    NSMutableArray<NSHTTPCookie *> *cookies = [NSMutableArray array];
    for (NSString *name in pairs) {
        NSString *value = pairs[name];
        if (value.length == 0) {
            continue;
        }
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{
            NSHTTPCookieName: name,
            NSHTTPCookieValue: value,
            NSHTTPCookieDomain: @".x.com",
            NSHTTPCookiePath: @"/",
        }];
        if (cookie) {
            [cookies addObject:cookie];
        }
    }

    if (cookies.count == 0) {
        done();
        return;
    }

    WKHTTPCookieStore *store = webView.configuration.websiteDataStore.httpCookieStore;
    __block NSUInteger remaining = cookies.count;
    for (NSHTTPCookie *cookie in cookies) {
        [store setCookie:cookie completionHandler:^{
            if (--remaining == 0) {
                done();
            }
        }];
    }
}

static void BHT_refreshWebCookiesViaWebView(void) {
    if (BHTWebHelperWebView) {
        BHT_refreshXTID();
        return;
    }
    if (BHTWebHelperInFlight) {
        return;
    }
    BHTWebHelperInFlight = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        BHT_harvestSharedCookies();

        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;

        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(-3000, -3000, 390, 844)
                                                configuration:configuration];
        BHTWebHelperDelegateInstance = [[BHTWebHelperDelegate alloc] init];
        webView.navigationDelegate = BHTWebHelperDelegateInstance;
        webView.customUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";
        webView.userInteractionEnabled = NO;
        webView.alpha = 0.01;
        BHTWebHelperWebView = webView;
        BHTWebHelperReady = NO;

        UIWindow *keyWindow = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) {
                keyWindow = w;
                break;
            }
        }
        keyWindow = keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
        [keyWindow addSubview:webView];

        BHT_seedHelperCookies(webView, ^{
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://x.com/settings/account"]]];
        });
    });
}

static void BHT_onHelperWebViewLoaded(WKWebView *webView) {
    BHTWebHelperInFlight = NO;

    [webView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
        BHT_storeWebCookies(cookies);
    }];

    NSString *script = nil;
    NSURL *scriptURL = [[BHTBundle sharedBundle] pathForFile:@"BHTWebXTID.js"];
    if (scriptURL) {
        script = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:nil];
    }
    if (script.length == 0) {
        return;
    }

    [webView evaluateJavaScript:script completionHandler:^(__unused id result, __unused NSError *error) {
        BHTWebHelperReady = YES;
        BHT_refreshXTID();
    }];
}

static void BHT_refreshXTID(void) {
    if (BHTWebXTIDInFlight) {
        return;
    }
    WKWebView *webView = BHTWebHelperWebView;
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }
    if (@available(iOS 14.0, *)) {
        BHTWebXTIDInFlight = YES;
        NSString *path = [NSString stringWithFormat:@"/graphql/%@/CreateTweet", BHTWebCreateTweetQueryID];

        dispatch_async(dispatch_get_main_queue(), ^{
            [webView callAsyncJavaScript:@"return await window.__bhtTransactionId(path, method);"
                               arguments:@{ @"method": @"POST", @"path": path }
                                 inFrame:nil
                          inContentWorld:WKContentWorld.pageWorld
                       completionHandler:^(id result, __unused NSError *error) {
                BHTWebXTIDInFlight = NO;
                BOOL ok = [result isKindOfClass:[NSString class]] &&
                          [(NSString *)result length] > 10 &&
                          ![(NSString *)result hasPrefix:@"BHTERR:"];
                if (ok) {
                    BHTWebXTID = [result copy];
                }
            }];
        });
    }
}

// MARK: - Native bootstrap webview (per-account web session)

// Some accounts (freshly added / legacy) have no web cookies yet. Only the native
// authenticated webview can perform the OAuth->cookie exchange, so we load one offscreen
// to establish and harvest that account's session.
static void BHT_bootstrapAccount(id account, NSString *userID) {
    if (!account || userID.length == 0 || BHTWebBootstrapInFlight) {
        return;
    }
    BHTWebBootstrapInFlight = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (BHTWebHarvestWindow) {
            BHTWebHarvestWindow.hidden = YES;
            BHTWebHarvestWindow.rootViewController = nil;
            BHTWebHarvestWindow = nil;
        }

        Class webViewControllerClass = %c(T1WebViewController);
        SEL initSel = @selector(initWithRootURL:account:shouldAuthenticate:shouldPresentAsNativePage:sourceStatus:scribeComponent:scribeParameters:);
        UIWindowScene *scene = BHT_activeWindowScene();
        if (!webViewControllerClass || !scene ||
            ![webViewControllerClass instancesRespondToSelector:initSel]) {
            BHTWebBootstrapInFlight = NO;
            return;
        }

        NSURL *url = [NSURL URLWithString:@"https://x.com/settings/account"];
        T1WebViewController *webViewController =
            [[webViewControllerClass alloc] initWithRootURL:url
                                                    account:account
                                         shouldAuthenticate:YES
                                  shouldPresentAsNativePage:NO
                                               sourceStatus:nil
                                            scribeComponent:nil
                                           scribeParameters:nil];
        if (!webViewController) {
            BHTWebBootstrapInFlight = NO;
            return;
        }

        objc_setAssociatedObject(webViewController, BHTWebHarvestWebViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        UIWindow *window = [[UIWindow alloc] initWithWindowScene:scene];
        window.frame = CGRectMake(-3000, -3000, 390, 844);
        window.windowLevel = UIWindowLevelNormal - 1000;
        window.userInteractionEnabled = NO;
        window.rootViewController = webViewController;
        window.hidden = NO;
        BHTWebHarvestWindow = window;

        // Safety teardown in case the load never resolves.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BHT_teardownWebHarvestWindow();
        });
    });
}

static void BHT_teardownWebHarvestWindow(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (BHTWebHarvestWindow) {
            BHTWebHarvestWindow.hidden = YES;
            BHTWebHarvestWindow.rootViewController = nil;
            BHTWebHarvestWindow = nil;
        }
        BHTWebBootstrapInFlight = NO;
    });
}

// Called from WebReply.x's T1WebViewController -didFinishLoadingWithError: hook. Harvests
// cookies out of a finished bootstrap webview, then tears its window down.
void BHT_maybeHandleHarvestWebView(__unsafe_unretained id webViewController) {
    if (!webViewController || !objc_getAssociatedObject(webViewController, BHTWebHarvestWebViewKey)) {
        return;
    }

    WKWebView *webView = nil;
    @try {
        if ([webViewController respondsToSelector:@selector(webView)]) {
            webView = ((WKWebView *(*)(id, SEL))objc_msgSend)(webViewController, @selector(webView));
        }
    } @catch (__unused NSException *exception) {}

    void (^finish)(void) = ^{
        BHT_harvestSharedCookies();
        BHT_refreshWebCookiesViaWebView();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BHT_teardownWebHarvestWindow();
        });
    };

    if ([webView isKindOfClass:%c(WKWebView)]) {
        [webView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
            BHT_storeWebCookies(cookies);
            finish();
        }];
    } else {
        finish();
    }
}

// MARK: - Prewarm

void BHT_prewarmWebCookiesIfNeeded(void) {
    if (!BHT_nativeCreateTweetInterceptEnabled()) {
        return;
    }

    NSString *savedQueryID = [[NSUserDefaults standardUserDefaults] stringForKey:BHTWebQueryIDDefaultsKey];
    if (savedQueryID.length) {
        BHTWebCreateTweetQueryID = [savedQueryID copy];
    }

    if (BHTWebHelperWebView) {
        BHT_refreshXTID();
    } else {
        BHT_refreshWebCookiesViaWebView();
    }

    BHT_harvestSharedCookies();

    id current = BHT_accountForAuthenticatedWebView();
    NSString *currentUserID = BHT_userIDStringForAccount(current);
    if (current && currentUserID.length && !BHT_cachedAccountPair(currentUserID)) {
        BHT_bootstrapAccount(current, currentUserID);
    }
}

// MARK: - Credential resolution

// Resolve the auth_token for an arbitrary account: the primary (web-session) account
// uses the harvested token directly; others come out of the auth_multi cookie.
static NSString *BHT_authTokenForUserID(NSString *userID) {
    if (userID.length == 0) {
        return nil;
    }

    NSString *primaryUID = BHT_userIDFromTwid(BHTWebTwid);
    if ([primaryUID isEqualToString:userID] && BHTWebAuthToken.length) {
        return BHTWebAuthToken;
    }

    if (BHTWebAuthMulti.length == 0) {
        return nil;
    }
    NSString *decoded = [BHTWebAuthMulti stringByRemovingPercentEncoding] ?: BHTWebAuthMulti;
    decoded = [decoded stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@"|,"];
    for (NSString *entry in [decoded componentsSeparatedByCharactersInSet:separators]) {
        NSRange colon = [entry rangeOfString:@":"];
        if (colon.location == NSNotFound) {
            continue;
        }
        NSString *uid = [entry substringToIndex:colon.location];
        NSString *token = [entry substringFromIndex:NSMaxRange(colon)];
        if ([uid isEqualToString:userID] && token.length) {
            return token;
        }
    }
    return nil;
}

@interface BHTCt0Fetcher : NSObject <NSURLSessionTaskDelegate>
@property (nonatomic, copy) NSString *ct0;
@property (nonatomic, copy) NSString *twid;
@property (nonatomic, assign) BOOL loggedOut;
- (void)captureFromResponse:(NSURLResponse *)response;
@end

@implementation BHTCt0Fetcher
- (void)captureFromResponse:(NSURLResponse *)response {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return;
    }
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:http.allHeaderFields
                                                                             forURL:http.URL ?: response.URL];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"ct0"] && cookie.value.length) {
            self.ct0 = [cookie.value copy];
        } else if ([cookie.name isEqualToString:@"twid"] && cookie.value.length) {
            self.twid = [cookie.value copy];
        }
    }
}
- (void)URLSession:(__unused NSURLSession *)session
              task:(__unused NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
    [self captureFromResponse:response];

    NSString *target = request.URL.absoluteString.lowercaseString ?: @"";
    if ([target containsString:@"login"] || [target containsString:@"logout"] ||
        [target containsString:@"/i/flow/"] || [target containsString:@"account/access"]) {
        self.loggedOut = YES;
    }
    completionHandler(request);
}
@end

// Mint a fresh ct0 for a bare auth_token by hitting x.com once and reading the Set-Cookie.
static NSString *BHT_fetchCt0Sync(NSString *authToken, NSString *expectedUserID) {
    if (authToken.length == 0 || [NSThread isMainThread]) {
        return nil;
    }

    BHTCt0Fetcher *fetcher = [BHTCt0Fetcher new];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.HTTPCookieStorage = nil;
    config.HTTPShouldSetCookies = NO;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:fetcher delegateQueue:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://x.com/"]];
    request.HTTPShouldHandleCookies = NO;
    [request setValue:[NSString stringWithFormat:@"auth_token=%@", authToken] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
   forHTTPHeaderField:@"User-Agent"];

    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    [[session dataTaskWithRequest:request completionHandler:^(__unused NSData *data,
                                                              NSURLResponse *response,
                                                              __unused NSError *error) {
        [fetcher captureFromResponse:response];
        dispatch_semaphore_signal(done);
    }] resume];
    dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)));
    [session finishTasksAndInvalidate];

    if (fetcher.loggedOut) {
        return nil;
    }

    NSString *responseUserID = BHT_userIDFromTwid(fetcher.twid);
    if (expectedUserID.length && responseUserID.length && ![responseUserID isEqualToString:expectedUserID]) {
        return nil;
    }
    return fetcher.ct0;
}

// Resolve credentials for the posting account, bootstrapping and minting as needed.
// Returns NO if the account can't be authenticated for web posting.
static BOOL BHT_resolveWebCreds(NSString *userID, NSString **outAuthToken, NSString **outCt0) {
    NSDictionary *cached = BHT_cachedAccountPair(userID);
    if (cached[@"auth_token"] && cached[@"ct0"]) {
        if (outAuthToken) *outAuthToken = cached[@"auth_token"];
        if (outCt0) *outCt0 = cached[@"ct0"];
        return YES;
    }

    NSString *authToken = nil, *ct0 = nil;
    NSString *token = BHT_authTokenForUserID(userID);

    for (int attempt = 0; attempt < 2 && ct0.length == 0; attempt++) {
        if (token.length == 0) {
            id account = BHT_accountForUserID(userID);
            if (!account) {
                break;
            }
            // Bootstrap a web session for this account, then read its token back out.
            BHT_waitUntil(^BOOL{
                BHT_harvestSharedCookies();
                return BHT_authTokenForUserID(userID).length > 0;
            }, ^{
                BHT_bootstrapAccount(account, userID);
            }, 30.0);
            token = BHT_authTokenForUserID(userID);
            if (token.length == 0) {
                break;
            }
        }

        NSString *fresh = BHT_fetchCt0Sync(token, userID);
        if (fresh.length) {
            authToken = token;
            ct0 = fresh;
            BHT_cacheAccountPair(userID, @{
                @"auth_token": token,
                @"ct0": fresh,
                @"twid": [NSString stringWithFormat:@"u=%@", userID],
            });
        } else {
            BHT_cacheAccountPair(userID, nil);
            token = nil;
        }
    }

    if (authToken.length == 0 || ct0.length == 0) {
        return NO;
    }
    if (outAuthToken) *outAuthToken = authToken;
    if (outCt0) *outCt0 = ct0;
    return YES;
}

// MARK: - Request transform

static BOOL BHT_isCreateTweetURL(NSURL *url) {
    return url && [url.path hasSuffix:@"/CreateTweet"];
}

// The queryId sits in the request path: .../graphql/<queryId>/CreateTweet
static NSString *BHT_queryIDFromCreateTweetURL(NSURL *url) {
    NSArray<NSString *> *components = url.path.pathComponents;
    if (components.count >= 2 && [components.lastObject isEqualToString:@"CreateTweet"]) {
        return components[components.count - 2];
    }
    return nil;
}

// The native request signs with OAuth: oauth_token="<userID>-<secret>".
static NSString *BHT_postingUserIDFromRequest(NSURLRequest *request) {
    NSString *auth = [request valueForHTTPHeaderField:@"Authorization"];
    if (![auth isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSRange marker = [auth rangeOfString:@"oauth_token=\""];
    if (marker.location == NSNotFound) {
        return nil;
    }
    NSString *rest = [auth substringFromIndex:NSMaxRange(marker)];
    NSRange endQuote = [rest rangeOfString:@"\""];
    if (endQuote.location == NSNotFound) {
        return nil;
    }
    NSString *token = [rest substringToIndex:endQuote.location];
    NSRange dash = [token rangeOfString:@"-"];
    return dash.location != NSNotFound ? [token substringToIndex:dash.location] : nil;
}

// Strip the native OAuth headers and re-authenticate the request against the web session.
static void BHT_applyWebAuth(NSMutableURLRequest *request, NSString *authToken, NSString *ct0, NSString *userID) {
    request.HTTPShouldHandleCookies = NO;

    for (NSString *header in @[@"Authorization", @"X-Twitter-Client-DeviceID", @"X-Twitter-Client-Version",
                               @"X-Twitter-Client", @"X-Twitter-API-Version", @"X-Twitter-Client-Limit-Ad-Tracking",
                               @"X-B3-TraceId", @"Timezone", @"kdt", @"X-Client-UUID"]) {
        [request setValue:nil forHTTPHeaderField:header];
    }

    [request setValue:BHTWebBearer forHTTPHeaderField:@"authorization"];
    [request setValue:@"OAuth2Session" forHTTPHeaderField:@"x-twitter-auth-type"];
    [request setValue:@"yes" forHTTPHeaderField:@"x-twitter-active-user"];
    if (ct0.length) {
        [request setValue:ct0 forHTTPHeaderField:@"x-csrf-token"];
    }

    NSMutableArray<NSString *> *cookiePairs = [NSMutableArray array];
    if (authToken.length) {
        [cookiePairs addObject:[NSString stringWithFormat:@"auth_token=%@", authToken]];
    }
    if (ct0.length) {
        [cookiePairs addObject:[NSString stringWithFormat:@"ct0=%@", ct0]];
    }
    if (userID.length) {
        [cookiePairs addObject:[NSString stringWithFormat:@"twid=u%%3D%@", userID]];
    }
    [request setValue:[cookiePairs componentsJoinedByString:@"; "] forHTTPHeaderField:@"Cookie"];
}

// If `request` is a native CreateTweet, return a web-authenticated copy; otherwise nil.
static NSMutableURLRequest *BHT_webRequestFromNativeSend(NSURLRequest *request) {
    if (!BHT_isCreateTweetURL(request.URL) || !BHT_nativeCreateTweetInterceptEnabled()) {
        return nil;
    }

    NSString *queryID = BHT_queryIDFromCreateTweetURL(request.URL);
    if (queryID.length && ![queryID isEqualToString:BHTWebCreateTweetQueryID]) {
        BHTWebCreateTweetQueryID = [queryID copy];
        [[NSUserDefaults standardUserDefaults] setObject:queryID forKey:BHTWebQueryIDDefaultsKey];
    }

    if (BHTWebXTID.length == 0) {
        BHT_waitUntil(^BOOL{ return BHTWebXTID.length > 0; }, ^{
            if (!BHTWebHelperWebView) {
                BHT_refreshWebCookiesViaWebView();
            } else if (BHTWebHelperReady) {
                BHT_refreshXTID();
            }
        }, 20.0);
        if (BHTWebXTID.length == 0) {
            return nil;
        }
    }

    BHT_harvestSharedCookies();

    NSString *postingUserID = BHT_postingUserIDFromRequest(request);
    if (postingUserID.length == 0) {
        return nil;
    }

    NSString *authToken = nil, *ct0 = nil;
    if (!BHT_resolveWebCreds(postingUserID, &authToken, &ct0)) {
        return nil;
    }

    NSMutableURLRequest *outgoing = [request mutableCopy];
    BHT_applyWebAuth(outgoing, authToken, ct0, postingUserID);
    [outgoing setValue:BHTWebXTID forHTTPHeaderField:@"x-client-transaction-id"];
    BHT_refreshXTID();

    // Tag the request so the task watcher can drop this account's ct0 on a 4xx.
    objc_setAssociatedObject(outgoing, BHTWebPostingUIDKey, postingUserID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return outgoing;
}

// MARK: - Task watcher

// Watches a rewritten CreateTweet task; on a 4xx it invalidates the cached ct0 so the
// next send re-mints.
@interface BHTCreateTweetWatcher : NSObject
@property (nonatomic, copy) NSString *userID;
@end

@implementation BHTCreateTweetWatcher
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(__unused NSDictionary *)change
                       context:(__unused void *)context {
    NSURLSessionTask *task = object;
    if (![keyPath isEqualToString:@"state"] || task.state != NSURLSessionTaskStateCompleted) {
        return;
    }

    BHTCreateTweetWatcher *keepAlive = self; // survive detaching our own retainer below
    @try {
        [task removeObserver:self forKeyPath:@"state"];
    } @catch (__unused NSException *exception) {}
    objc_setAssociatedObject(task, BHTCreateTweetWatcherKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSInteger code = [task.response isKindOfClass:[NSHTTPURLResponse class]]
        ? [(NSHTTPURLResponse *)task.response statusCode] : 0;
    if (code >= 400 && code < 500 && keepAlive.userID.length) {
        BHT_cacheAccountPair(keepAlive.userID, nil);
    }
}
@end

static void BHT_watchCreateTweetTask(id task, NSString *userID) {
    if (![task isKindOfClass:[NSURLSessionTask class]] || userID.length == 0) {
        return;
    }
    BHTCreateTweetWatcher *watcher = [BHTCreateTweetWatcher new];
    watcher.userID = userID;
    objc_setAssociatedObject(task, BHTCreateTweetWatcherKey, watcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try {
        [task addObserver:watcher forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:NULL];
    } @catch (__unused NSException *exception) {}
}

// MARK: - Shared account accessor

id BHT_accountForAuthenticatedWebView(void) {
    Class hostClass = %c(T1HostViewController);
    if ([hostClass respondsToSelector:@selector(sharedHostViewController)]) {
        id host = [hostClass sharedHostViewController];
        if ([host respondsToSelector:@selector(currentAccount)]) {
            id account = [host currentAccount];
            if (account) {
                return account;
            }
        }
    }
    return nil;
}

// MARK: - Hooks

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    NSMutableURLRequest *outgoing = BHT_webRequestFromNativeSend(request);
    if (outgoing) {
        NSURLSessionDataTask *task = %orig(outgoing);
        BHT_watchCreateTweetTask(task, objc_getAssociatedObject(outgoing, BHTWebPostingUIDKey));
        return task;
    }
    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(id)completionHandler {
    NSMutableURLRequest *outgoing = BHT_webRequestFromNativeSend(request);
    if (outgoing) {
        NSURLSessionDataTask *task = %orig(outgoing, completionHandler);
        BHT_watchCreateTweetTask(task, objc_getAssociatedObject(outgoing, BHTWebPostingUIDKey));
        return task;
    }
    return %orig;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData {
    NSMutableURLRequest *outgoing = BHT_webRequestFromNativeSend(request);
    if (outgoing) {
        NSURLSessionUploadTask *task = %orig(outgoing, bodyData);
        BHT_watchCreateTweetTask(task, objc_getAssociatedObject(outgoing, BHTWebPostingUIDKey));
        return task;
    }
    return %orig;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL {
    NSMutableURLRequest *outgoing = BHT_webRequestFromNativeSend(request);
    if (outgoing) {
        NSURLSessionUploadTask *task = %orig(outgoing, fileURL);
        BHT_watchCreateTweetTask(task, objc_getAssociatedObject(outgoing, BHTWebPostingUIDKey));
        return task;
    }
    return %orig;
}

%end
