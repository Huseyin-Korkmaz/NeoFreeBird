//
//  SourceLabels.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Restore Tweet Source Labels
//
// Twitter removed the "via Twitter for iPhone" source line from the tweet detail
// footer. The source is no longer present in the on-device status models, so we
// fetch it from the legacy conversation API using the signed-in account's own
// cookies and cache it keyed by tweet ID. The label is then injected into the
// detail footer by appending it to the footer item's time string, which the
// native footer builder renders for us. Original idea by @nyaathea.

// Shared with Branding.x for source-label coloring (declared in BHTHookHelpers.h).
NSMutableDictionary *tweetSources = nil;

// Per-tweet fetch bookkeeping. All of these — including tweetSources — are only
// mutated on the main thread, so no locking is required.
static NSMutableDictionary *fetchPending = nil;
static NSMutableDictionary *fetchRetries = nil;

static char kBHTSourceAppendedKey;      // marks a footer item whose timeAgo already carries the source
static char kBHTFooterTweetIDKey;       // the tweet ID a footer text view is currently showing
static char kBHTFooterObservingKey;     // whether a footer text view registered for update notifications

#define BHT_SOURCE_NOTE          @"BHTTweetSourceUpdated"
#define MAX_SOURCE_CACHE_SIZE    200
#define MAX_FETCH_RETRIES        3

// Public web bearer token (not a secret; ships in the web client).
static NSString * const kBHTSourceBearer =
    @"Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA";

// --- Model / view seams verified against classdump/12.3 (T1Twitter.c) ---

@interface T1ConversationFooterItem : NSObject
@property (nonatomic, copy) NSString *timeAgo;
@end

@interface T1ConversationFooterTextView (BHTSourceLabels)
@property (nonatomic, readonly) T1ConversationFooterItem *footerItem;
@end

// TweetSourceHelper itself is declared in Headers/BHTHelpers.h; declare only the
// internals this rewrite adds.
@interface TweetSourceHelper (BHTSourceLabels)
+ (NSString *)unavailableString;
+ (NSDictionary *)currentCookies;
+ (void)pruneCacheIfNeeded;
+ (NSString *)labelFromSourceHTML:(NSString *)html;
+ (void)markTweetID:(NSString *)tweetID unavailable:(BOOL)unavailable withSource:(NSString *)source;
+ (void)retryOrFailTweetID:(NSString *)tweetID;
@end

@implementation TweetSourceHelper

+ (NSString *)unavailableString {
    return [[BHTBundle sharedBundle] localizedStringForKey:@"SOURCE_UNAVAILABLE"];
}

// Both cookies must belong to the signed-in account for the request to authorize.
+ (NSDictionary *)currentCookies {
    NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
    NSArray *domains = @[@"https://x.com", @"https://twitter.com", @"https://api.twitter.com", @"https://api.x.com"];

    for (NSString *domain in domains) {
        NSURL *url = [NSURL URLWithString:domain];
        for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url]) {
            if (([cookie.name isEqualToString:@"ct0"] || [cookie.name isEqualToString:@"auth_token"]) && cookie.value.length) {
                cookies[cookie.name] = cookie.value;
            }
        }
    }

    return cookies;
}

// Keeps the cache from growing without bound by dropping resolved/unavailable entries.
+ (void)pruneCacheIfNeeded {
    if (tweetSources.count <= MAX_SOURCE_CACHE_SIZE) return;

    NSString *unavailable = [self unavailableString];
    NSMutableArray *keysToRemove = [NSMutableArray array];

    for (NSString *key in tweetSources) {
        NSString *value = tweetSources[key];
        if (value.length == 0 || [value isEqualToString:unavailable]) {
            [keysToRemove addObject:key];
        }
    }

    for (NSString *key in keysToRemove) {
        [tweetSources removeObjectForKey:key];
        [fetchPending removeObjectForKey:key];
        [fetchRetries removeObjectForKey:key];
    }
}

// Extracts the visible label from the "<a ...>Twitter for iPhone</a>" source markup.
+ (NSString *)labelFromSourceHTML:(NSString *)html {
    if (html.length == 0) return nil;

    NSRange open = [html rangeOfString:@">"];
    NSRange close = [html rangeOfString:@"</a>"];
    if (open.location == NSNotFound || close.location == NSNotFound || open.location + 1 >= close.location) {
        return nil;
    }

    NSString *label = [html substringWithRange:NSMakeRange(open.location + 1, close.location - open.location - 1)];
    return [label stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (void)markTweetID:(NSString *)tweetID unavailable:(BOOL)unavailable withSource:(NSString *)source {
    // Always resolves back on the main thread where the cache lives.
    dispatch_async(dispatch_get_main_queue(), ^{
        [fetchPending removeObjectForKey:tweetID];

        if (unavailable) {
            tweetSources[tweetID] = [self unavailableString];
        } else {
            tweetSources[tweetID] = source;
            [fetchRetries removeObjectForKey:tweetID];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:BHT_SOURCE_NOTE
                                                            object:nil
                                                          userInfo:@{@"tweetID": tweetID}];
    });
}

+ (void)retryOrFailTweetID:(NSString *)tweetID {
    dispatch_async(dispatch_get_main_queue(), ^{
        [fetchPending removeObjectForKey:tweetID];

        NSInteger retries = [fetchRetries[tweetID] integerValue];
        if (retries >= MAX_FETCH_RETRIES) {
            [self markTweetID:tweetID unavailable:YES withSource:nil];
            return;
        }

        fetchRetries[tweetID] = @(retries + 1);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fetchSourceForTweetID:tweetID];
        });
    });
}

// Must be called on the main thread.
+ (void)fetchSourceForTweetID:(NSString *)tweetID {
    if (tweetID.length == 0) return;

    [self pruneCacheIfNeeded];

    if ([fetchPending[tweetID] boolValue]) return;

    NSString *existing = tweetSources[tweetID];
    if (existing.length > 0 && ![existing isEqualToString:[self unavailableString]]) return;

    NSDictionary *cookies = [self currentCookies];
    if (!cookies[@"ct0"] || !cookies[@"auth_token"]) {
        [self markTweetID:tweetID unavailable:YES withSource:nil];
        return;
    }

    NSString *urlString = [NSString stringWithFormat:
        @"https://api.twitter.com/2/timeline/conversation/%@.json?tweet_mode=extended", tweetID];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self markTweetID:tweetID unavailable:YES withSource:nil];
        return;
    }

    fetchPending[tweetID] = @(YES);

    NSMutableArray *cookiePairs = [NSMutableArray array];
    for (NSString *name in cookies) {
        [cookiePairs addObject:[NSString stringWithFormat:@"%@=%@", name, cookies[name]]];
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 10.0;
    [request setValue:kBHTSourceBearer forHTTPHeaderField:@"Authorization"];
    [request setValue:@"OAuth2Session" forHTTPHeaderField:@"x-twitter-auth-type"];
    [request setValue:@"1" forHTTPHeaderField:@"x-twitter-active-user"];
    [request setValue:cookies[@"ct0"] forHTTPHeaderField:@"x-csrf-token"];
    [request setValue:[cookiePairs componentsJoinedByString:@"; "] forHTTPHeaderField:@"Cookie"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;

        if (error || !data || http.statusCode != 200) {
            [self retryOrFailTweetID:tweetID];
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
            [self retryOrFailTweetID:tweetID];
            return;
        }

        NSDictionary *tweets = json[@"globalObjects"][@"tweets"];
        NSDictionary *tweet = tweets[tweetID];
        if (![tweet isKindOfClass:[NSDictionary class]]) {
            [self markTweetID:tweetID unavailable:YES withSource:nil];
            return;
        }

        NSString *label = [self labelFromSourceHTML:tweet[@"source"]];
        if (label.length == 0) {
            label = [[BHTBundle sharedBundle] localizedStringForKey:@"UNKNOWN_SOURCE"];
        }

        [self markTweetID:tweetID unavailable:NO withSource:label];
    }];
    [task resume];
}

@end


// MARK: Footer injection
//
// -updateFooterTextView is the single funnel that rebuilds the detail footer's
// attributed text from footerItem.timeAgo. Appending the source to timeAgo before
// %orig lets the native builder lay it out; when the source arrives asynchronously
// we simply re-run the method.

%hook T1ConversationFooterTextView

- (void)updateFooterTextView {
    if (![BHTSettings boolForKey:@"restore_tweet_labels"]) {
        %orig;
        return;
    }

    @try {
        id viewModel = self.viewModel;
        id status = [viewModel respondsToSelector:@selector(tweet)] ? [viewModel performSelector:@selector(tweet)] : nil;

        NSString *tweetID = nil;
        if ([status respondsToSelector:@selector(statusID)]) {
            long long statusID = [(TFNTwitterStatus *)status statusID];
            if (statusID > 0) tweetID = [NSString stringWithFormat:@"%lld", statusID];
        }

        if (tweetID.length > 0) {
            objc_setAssociatedObject(self, &kBHTFooterTweetIDKey, tweetID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            if (![objc_getAssociatedObject(self, &kBHTFooterObservingKey) boolValue]) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(BHT_tweetSourceUpdated:)
                                                             name:BHT_SOURCE_NOTE
                                                           object:nil];
                objc_setAssociatedObject(self, &kBHTFooterObservingKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }

            NSString *source = tweetSources[tweetID];

            if (source == nil) {
                tweetSources[tweetID] = @""; // placeholder so we only fetch once
                [TweetSourceHelper fetchSourceForTweetID:tweetID];
            } else if (source.length > 0 && ![source isEqualToString:[TweetSourceHelper unavailableString]]) {
                T1ConversationFooterItem *footerItem = self.footerItem;
                NSString *timeAgo = footerItem.timeAgo;

                if (footerItem && timeAgo.length > 0 &&
                    ![objc_getAssociatedObject(footerItem, &kBHTSourceAppendedKey) boolValue] &&
                    ![timeAgo containsString:source]) {

                    footerItem.timeAgo = [NSString stringWithFormat:@"%@ · %@", timeAgo, source];
                    objc_setAssociatedObject(footerItem, &kBHTSourceAppendedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }
        }
    } @catch (__unused NSException *e) {}

    %orig;
}

%new
- (void)BHT_tweetSourceUpdated:(NSNotification *)notification {
    NSString *tweetID = notification.userInfo[@"tweetID"];
    NSString *mine = objc_getAssociatedObject(self, &kBHTFooterTweetIDKey);
    if (tweetID.length > 0 && [tweetID isEqualToString:mine]) {
        // Posted from the main queue, so we are already on the main thread here.
        [self updateFooterTextView];
    }
}

- (void)dealloc {
    if ([objc_getAssociatedObject(self, &kBHTFooterObservingKey) boolValue]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:BHT_SOURCE_NOTE object:nil];
    }
    %orig;
}

%end


%ctor {
    if (!tweetSources) tweetSources = [NSMutableDictionary dictionary];
    if (!fetchPending) fetchPending = [NSMutableDictionary dictionary];
    if (!fetchRetries) fetchRetries = [NSMutableDictionary dictionary];

    %init;
}
