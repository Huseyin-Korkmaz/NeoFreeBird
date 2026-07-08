//
//  SourceLabels.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

static char kBHTSourceTapAddedKey;

// start of NFB features

// MARK: Restore Source Labels - This is still pretty experimental and may break. This restores Tweet Source Labels by using an Legacy API. by: @nyaathea

NSMutableDictionary *tweetSources             = nil;
static NSMutableDictionary *viewToTweetID     = nil;
static NSMutableDictionary *fetchTimeouts     = nil;
static NSMutableDictionary *viewInstances     = nil;
static NSMutableDictionary *fetchRetries      = nil;
static NSMutableDictionary *fetchPending      = nil;
static NSMutableDictionary *cookieCache       = nil;
static NSDate *lastCookieRefresh              = nil;

// Add a dispatch queue for thread-safe access to shared data
static dispatch_queue_t sourceLabelDataQueue = nil;

// --- Networking & Helper Implementation ---
// Full interface already declared at the top of the file

#define MAX_SOURCE_CACHE_SIZE 200 // Reduced cache size to prevent memory issues
#define MAX_CONSECUTIVE_FAILURES 3 // Maximum consecutive failures before backing off

@implementation TweetSourceHelper

+ (void)logDebugInfo:(NSString *)message {
    // Only log in debug mode to reduce log spam
#if BHT_DEBUG
    if (message) {
    }
#endif
}

+ (void)initializeCookiesWithRetry {
    // Simplified initialization - just load hardcoded cookies
    NSDictionary *hardcodedCookies = [self fetchCookies];
    [self cacheCookies:hardcodedCookies];
}

+ (void)pruneSourceCachesIfNeeded {
    // This is a write operation, use a barrier
    dispatch_barrier_async(sourceLabelDataQueue, ^{
        if (!tweetSources) return;

        __block NSUInteger count = 0;
        count = tweetSources.count;

        if (count > MAX_SOURCE_CACHE_SIZE) {
            [self logDebugInfo:[NSString stringWithFormat:@"Pruning cache with %ld entries", (long)count]];

            NSMutableArray *keysToRemove = [NSMutableArray array];

            [tweetSources enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (!obj || [obj isEqualToString:@""] || [obj isEqualToString:@"Source Unavailable"]) {
                    [keysToRemove addObject:key];
                    if (keysToRemove.count >= count / 4) *stop = YES;
                }
            }];

            if (keysToRemove.count < count / 5) {
                NSArray *allKeys = [tweetSources allKeys];
                for (int i = 0; i < 20 && keysToRemove.count < count / 4; i++) {
                    NSString *randomKey = allKeys[arc4random_uniform((uint32_t)allKeys.count)];
                    if (![keysToRemove containsObject:randomKey]) {
                        [keysToRemove addObject:randomKey];
                    }
                }
            }

            [self logDebugInfo:[NSString stringWithFormat:@"Removing %ld cache entries", (long)keysToRemove.count]];

            for (NSString *key in keysToRemove) {
                [tweetSources removeObjectForKey:key];

                NSTimer *timeoutTimer = fetchTimeouts[key];
                if (timeoutTimer) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [timeoutTimer invalidate];
                    });
                    [fetchTimeouts removeObjectForKey:key];
                }
                [fetchRetries removeObjectForKey:key];
                [fetchPending removeObjectForKey:key];
            }
        }
    });
}

+ (NSDictionary *)fetchCookies {
    // First try to get real cookies from the user's actual account
    NSMutableDictionary *realCookies = [NSMutableDictionary dictionary];
    NSArray *domains = @[@"api.twitter.com", @".twitter.com", @"x.com", @"api.x.com"];
    NSArray *requiredCookies = @[@"ct0", @"auth_token"];

    for (NSString *domain in domains) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", domain]];
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
        for (NSHTTPCookie *cookie in cookies) {
            if ([requiredCookies containsObject:cookie.name]) {
                realCookies[cookie.name] = cookie.value;
            }
        }
    }

    // Check if we have valid real cookies
    BOOL hasValidRealCookies = realCookies.count > 0 &&
                               realCookies[@"ct0"] && realCookies[@"auth_token"] &&
                               [realCookies[@"ct0"] length] > 10 &&
                               [realCookies[@"auth_token"] length] > 10;

    if (hasValidRealCookies) {
        [self logDebugInfo:@"Using real user cookies"];
        return [realCookies copy];
    } else {
        // Fall back to hardcoded cookies for reliability
        [self logDebugInfo:@"Falling back to hardcoded alt cookies"];
        return @{
            @"ct0": @"91cc6876b96a35f91adeedc4ef149947c4d58907ca10fc2b17f64b17db0cccfb714ae61ede34cf34866166dcaf8e1c3a86085fa35c41aacc3e3927f7aa1f9b850b49139ad7633344059ff04af302d5d3",
            @"auth_token": @"71fc90d6010d76ec4473b3e42c6802a8f1185316",
            @"twid": @"u%3D1930115366878871552"
        };
    }
}

+ (void)cacheCookies:(NSDictionary *)cookies {
    // Simplified caching - just store in memory since we're using hardcoded values
    cookieCache = [cookies mutableCopy];
    lastCookieRefresh = [NSDate date];
}

+ (NSDictionary *)loadCachedCookies {
    // Always return hardcoded cookies
    NSDictionary *hardcodedCookies = [self fetchCookies];
    cookieCache = [hardcodedCookies mutableCopy];
    lastCookieRefresh = [NSDate date];
    return hardcodedCookies;
}

+ (void)fetchSourceForTweetID:(NSString *)tweetID {
    if (!tweetID) return;

    // Defer the entire operation to our concurrent queue to handle state checks and request creation safely
    dispatch_async(sourceLabelDataQueue, ^{
        @try {
            // Initialize dictionaries if needed
            if (!tweetSources) tweetSources = [NSMutableDictionary dictionary];
            if (!fetchTimeouts) fetchTimeouts = [NSMutableDictionary dictionary];
            if (!fetchRetries) fetchRetries = [NSMutableDictionary dictionary];
            if (!fetchPending) fetchPending = [NSMutableDictionary dictionary];

            // Simple cache size management
            if (tweetSources.count > MAX_SOURCE_CACHE_SIZE) {
                // Pruning is now async, so we just call it
                [self pruneSourceCachesIfNeeded];
            }

        // Skip if already pending or has valid result
        if ([fetchPending[tweetID] boolValue] ||
            (tweetSources[tweetID] && ![tweetSources[tweetID] isEqualToString:@""] && ![tweetSources[tweetID] isEqualToString:@"Source Unavailable"])) {
            return;
        }

        // Check retry limit
        NSInteger retryCount = [fetchRetries[tweetID] integerValue];
        if (retryCount >= MAX_CONSECUTIVE_FAILURES) {
            tweetSources[tweetID] = @"Source Unavailable";
            return;
        }

        fetchPending[tweetID] = @(YES);
        fetchRetries[tweetID] = @(retryCount + 1);

                // Set simple timeout on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:8.0
                                                                    target:self
                                                                  selector:@selector(timeoutFetchForTweetID:)
                                                                  userInfo:@{@"tweetID": tweetID}
                                                                   repeats:NO];
            dispatch_barrier_async(sourceLabelDataQueue, ^{
                fetchTimeouts[tweetID] = timeoutTimer;
            });
        });

        // Build request
        NSString *urlString = [NSString stringWithFormat:@"https://api.twitter.com/2/timeline/conversation/%@.json?include_ext_alt_text=true&include_reply_count=true&tweet_mode=extended", tweetID];
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) {
            [self handleFetchFailure:tweetID];
            return;
        }

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"GET";
        request.timeoutInterval = 7.0;

        // Get cookies
        if (!cookieCache) {
            [self loadCachedCookies];
        }
        NSDictionary *cookiesToUse = cookieCache;

        // Check if using real cookies
        BOOL usingRealCookies = cookiesToUse &&
                               ![cookiesToUse[@"ct0"] isEqualToString:@"91cc6876b96a35f91adeedc4ef149947c4d58907ca10fc2b17f64b17db0cccfb714ae61ede34cf34866166dcaf8e1c3a86085fa35c41aacc3e3927f7aa1f9b850b49139ad7633344059ff04af302d5d3"];

        // Build headers
        NSMutableArray *cookieStrings = [NSMutableArray array];
        for (NSString *cookieName in cookiesToUse) {
            [cookieStrings addObject:[NSString stringWithFormat:@"%@=%@", cookieName, cookiesToUse[cookieName]]];
        }

        [request setValue:@"Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA" forHTTPHeaderField:@"Authorization"];
        [request setValue:@"OAuth2Session" forHTTPHeaderField:@"x-twitter-auth-type"];
        [request setValue:@"CFNetwork/1331.0.7 Darwin/25.2.0" forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [request setValue:cookiesToUse[@"ct0"] forHTTPHeaderField:@"x-csrf-token"];
        [request setValue:[cookieStrings componentsJoinedByString:@"; "] forHTTPHeaderField:@"Cookie"];

        // Execute request
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // The completion handler runs on a background thread
            // We must use our queue to modify shared state
            dispatch_barrier_async(sourceLabelDataQueue, ^{
                @try {
                    // Cleanup timeout
                    NSTimer *timer = fetchTimeouts[tweetID];
                    if (timer) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [timer invalidate];
                        });
                        [fetchTimeouts removeObjectForKey:tweetID];
                    }
                    fetchPending[tweetID] = @(NO);

                // Handle errors
                if (error || !data) {
                    [self handleFetchFailure:tweetID];
                    return;
                }

                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

                // Handle auth errors with fallback
                if ((httpResponse.statusCode == 401 || httpResponse.statusCode == 403) && usingRealCookies && retryCount == 1) {
                    // Try hardcoded cookies once
                    NSDictionary *hardcodedCookies = @{
                        @"ct0": @"91cc6876b96a35f91adeedc4ef149947c4d58907ca10fc2b17f64b17db0cccfb714ae61ede34cf34866166dcaf8e1c3a86085fa35c41aacc3e3927f7aa1f9b850b49139ad7633344059ff04af302d5d3",
                        @"auth_token": @"71fc90d6010d76ec4473b3e42c6802a8f1185316",
                        @"twid": @"u%3D1930115366878871552"
                    };
                                            [self cacheCookies:hardcodedCookies];
                        [self fetchSourceForTweetID:tweetID]; // Re-call, which will be queued
                        return;
                }

                if (httpResponse.statusCode != 200) {
                    [self handleFetchFailure:tweetID];
                    return;
                }

                // Parse JSON
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (jsonError || !json) {
                    [self handleFetchFailure:tweetID];
                    return;
                }

                // Extract source
                NSDictionary *tweets = json[@"globalObjects"][@"tweets"];
                NSDictionary *tweetData = tweets[tweetID];

                // Try alternate ID format if not found
                if (!tweetData) {
                    for (NSString *key in tweets) {
                        if ([key longLongValue] == [tweetID longLongValue]) {
                            tweetData = tweets[key];
                            break;
                        }
                    }
                }

                NSString *sourceHTML = tweetData[@"source"];
                NSString *sourceText = @"Unknown Source";

                if (sourceHTML) {
                    NSRange startRange = [sourceHTML rangeOfString:@">"];
                    NSRange endRange = [sourceHTML rangeOfString:@"</a>"];
                    if (startRange.location != NSNotFound && endRange.location != NSNotFound && startRange.location + 1 < endRange.location) {
                        sourceText = [sourceHTML substringWithRange:NSMakeRange(startRange.location + 1, endRange.location - startRange.location - 1)];
                        sourceText = [sourceText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    }
                    }

                // Store and notify
                    tweetSources[tweetID] = sourceText;
                fetchRetries[tweetID] = @(0); // Reset on success

                dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TweetSourceUpdated" object:nil userInfo:@{@"tweetID": tweetID}];
                    [self updateFooterTextViewsForTweetID:tweetID];
                });

                            } @catch (NSException *e) {
                    [self handleFetchFailure:tweetID];
                }
            });
        }];
        [task resume];

        } @catch (NSException *e) {
            [self handleFetchFailure:tweetID];
        }
    });
}

+ (void)handleFetchFailure:(NSString *)tweetID {
    if (!tweetID) return;

    // This is a write operation, but it's called from other synchronized blocks
    // So we don't need to wrap it again, but the caller must be synchronized
    fetchPending[tweetID] = @(NO);
    NSTimer *timer = fetchTimeouts[tweetID];
    if (timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [timer invalidate];
        });
        [fetchTimeouts removeObjectForKey:tweetID];
    }

    NSInteger retryCount = [fetchRetries[tweetID] integerValue];
    if (retryCount < MAX_CONSECUTIVE_FAILURES) {
        // Simple retry after delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), sourceLabelDataQueue, ^{
            [self fetchSourceForTweetID:tweetID];
        });
    } else {
        // Mark as unavailable
        tweetSources[tweetID] = @"Source Unavailable";
        dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TweetSourceUpdated" object:nil userInfo:@{@"tweetID": tweetID}];
        });
    }
}

+ (void)timeoutFetchForTweetID:(NSTimer *)timer {
    NSString *tweetID = timer.userInfo[@"tweetID"];
    if (!tweetID) return;

    dispatch_barrier_async(sourceLabelDataQueue, ^{
        // Safely invalidate timer on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([timer isValid]) {
                [timer invalidate];
            }
        });
        [fetchTimeouts removeObjectForKey:tweetID];
        [self handleFetchFailure:tweetID];
    });
}

+ (void)handleAppForeground:(NSNotification *)notification {
    // Removed complex app foreground handling
}

+ (void)handleClearCacheNotification:(NSNotification *)notification {
    // Simplified cache clearing - just clear the source cache
    if (tweetSources) [tweetSources removeAllObjects];
}

+ (void)cleanupTimersForBackground {
    // Clean up timers to prevent crashes when app resumes
    if (fetchTimeouts) {
        dispatch_barrier_async(sourceLabelDataQueue, ^{
            for (NSTimer *timer in [fetchTimeouts allValues]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([timer isValid]) {
                        [timer invalidate];
                    }
                });
            }
            [fetchTimeouts removeAllObjects];
        });
    }
}

+ (void)updateFooterTextViewsForTweetID:(NSString *)tweetID {
    // Removed notification-based updates
}

@end

%hook TFNTwitterStatus

- (id)init {
    id originalSelf = %orig;
    @try {
        NSInteger statusID = self.statusID;
        if (statusID > 0) {
            NSString *tweetIDStr = @(statusID).stringValue;
            // Write operation
            dispatch_barrier_async(sourceLabelDataQueue, ^{
                if (!tweetSources) tweetSources = [NSMutableDictionary dictionary];
                if (!tweetSources[tweetIDStr]) {
                    [TweetSourceHelper pruneSourceCachesIfNeeded]; // This is async now
                    tweetSources[tweetIDStr] = @"";
                    [TweetSourceHelper fetchSourceForTweetID:tweetIDStr];
                }
            });
        }
    } @catch (__unused NSException *e) {}
    return originalSelf;
}

%end

// Declare the category interface first
@interface TweetSourceHelper (Notifications)
+ (void)handleCookiesReadyNotification:(NSNotification *)notification;
@end

// Simplified implementation without notifications
@implementation TweetSourceHelper (Notifications)
+ (void)handleCookiesReadyNotification:(NSNotification *)notification {
    // Removed complex notification handling - now handled directly in fetchSourceForTweetID
}
@end

%hook T1ConversationFocalStatusView

- (void)setViewModel:(id)viewModel {
    %orig;
    @try {
        if (viewModel) {
            id status = nil;
            @try { status = [viewModel valueForKey:@"tweet"]; } @catch (__unused NSException *e) {}
            if (status) {
                NSInteger statusID = 0;
                @try {
                    statusID = [[status valueForKey:@"statusID"] integerValue];
                    if (statusID > 0) {
                        if (!tweetSources)   tweetSources   = [NSMutableDictionary dictionary];
                        if (!viewToTweetID)  viewToTweetID  = [NSMutableDictionary dictionary];
                        if (!viewInstances)  viewInstances  = [NSMutableDictionary dictionary];

                        NSString *tweetIDStr = @(statusID).stringValue;

                        if (!tweetSources[tweetIDStr]) {
                            tweetSources[tweetIDStr] = @"";
                            [TweetSourceHelper fetchSourceForTweetID:tweetIDStr];
                        }
                    }
                } @catch (__unused NSException *e) {}

                if (statusID <= 0) {
                    @try {
                        NSString *altID = [status valueForKey:@"rest_id"] ?: [status valueForKey:@"id_str"] ?: [status valueForKey:@"id"];
                        if (altID) {
                            if (!tweetSources)   tweetSources   = [NSMutableDictionary dictionary];
                            if (!viewToTweetID)  viewToTweetID  = [NSMutableDictionary dictionary];
                            if (!viewInstances)  viewInstances  = [NSMutableDictionary dictionary];

                            if (!tweetSources[altID]) {
                                [TweetSourceHelper pruneSourceCachesIfNeeded]; // ADDING THIS CALL HERE
                                tweetSources[altID] = @"";
                                [TweetSourceHelper fetchSourceForTweetID:altID];
                            }
                        }
                    } @catch (__unused NSException *e) {}
                }
            }
        }
    } @catch (__unused NSException *e) {}
}

- (void)dealloc {
    // Removed complex view tracking cleanup
    %orig;
}

- (void)handleTweetSourceUpdated:(NSNotification *)notification {
    @try {
        NSDictionary *userInfo = notification.userInfo;
        NSString *tweetID      = userInfo[@"tweetID"];
        if (tweetID && tweetSources[tweetID] && ![tweetSources[tweetID] isEqualToString:@""]) {
            NSValue *viewValue = viewInstances[tweetID];
            UIView  *targetView    = viewValue ? [viewValue nonretainedObjectValue] : nil; // Renamed to targetView for clarity
            if (targetView && targetView == self) { // Ensure we are updating the correct instance
                NSString *currentTweetID = viewToTweetID[@((uintptr_t)targetView)];
                if (currentTweetID && [currentTweetID isEqualToString:tweetID]) {
                    BH_EnumerateSubviewsRecursively(targetView, ^(UIView *subview) { // Use the static helper
                        if ([subview isKindOfClass:%c(TFNAttributedTextView)]) {
                            TFNAttributedTextView *textView = (TFNAttributedTextView *)subview;
                            TFNAttributedTextModel *model = [textView valueForKey:@"_textModel"];
                            if (model && model.attributedString.string) {
                                NSString *text = model.attributedString.string;
                                // Check for typical timestamp patterns or if the source might need to be appended/updated
                                if ([text containsString:@"PM"] || [text containsString:@"AM"] ||
                                    [text rangeOfString:@"\\\\d{1,2}[:.]\\\\d{1,2}" options:NSRegularExpressionSearch].location != NSNotFound) {

                                    // Check if this specific TFNAttributedTextView is NOT part of a quoted status view
                                    BOOL isSafeToUpdate = YES;
                                    UIView *parentCheck = textView;
                                    while(parentCheck && parentCheck != targetView) { // Traverse up to the main focal view
                                        if ([NSStringFromClass([parentCheck class]) isEqualToString:@"T1QuotedStatusView"]) {
                                            isSafeToUpdate = NO;
                                            break;
                                        }
                                        parentCheck = parentCheck.superview;
                                    }

                                    if (isSafeToUpdate) {
                                        // Force a refresh of the text model.
                                        // This will trigger setTextModel: again, where the source appending logic resides.
                                    [textView setTextModel:nil];
                                    [textView setTextModel:model];
                                }
                            }
                        }
                        }
                    });
                }
            }
        }
    } @catch (NSException *e) {
         NSLog(@"TweetSourceTweak: Exception in handleTweetSourceUpdated for T1ConversationFocalStatusView: %@", e);
    }
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Observe for our own update notifications
        [[NSNotificationCenter defaultCenter] addObserver:self // Target is the class itself for class methods
                                                 selector:@selector(handleTweetSourceUpdatedNotificationDispatch:) // A new dispatcher
                                                     name:@"TweetSourceUpdated"
                                                   object:nil];
        // Removed all notification observers - they were causing crashes
    });
}

// New class method to dispatch instance method calls
%new + (void)handleTweetSourceUpdatedNotificationDispatch:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *tweetID = userInfo[@"tweetID"];
    if (tweetID) {
        NSValue *viewValue = viewInstances[tweetID]; // viewInstances is a global static
        T1ConversationFocalStatusView *targetInstance = viewValue ? [viewValue nonretainedObjectValue] : nil;
        if (targetInstance && [targetInstance isKindOfClass:[self class]]) { // Check if it's an instance of T1ConversationFocalStatusView
            // Use performSelector for %new instance method from %new class method
            if ([targetInstance respondsToSelector:@selector(handleTweetSourceUpdated:)]) {
                [targetInstance performSelector:@selector(handleTweetSourceUpdated:) withObject:notification];
            } else {
                NSLog(@"TweetSourceTweak: ERROR - T1ConversationFocalStatusView instance does not respond to handleTweetSourceUpdated:");
            }
        }
    }
}


%end

// MARK: - Source Labels via T1ConversationFocalStatusView (Clean Approach)

@interface T1ConversationFocalStatusView (BHTSourceLabels)
- (void)BHT_updateFooterTextWithSource:(NSString *)sourceText tweetID:(NSString *)tweetID;
- (id)footerTextView;
@end

%hook T1ConversationFocalStatusView

- (void)setViewModel:(id)viewModel options:(unsigned long long)options account:(id)account {
    %orig(viewModel, options, account);

    if (![BHTSettings boolForKey:@"restore_tweet_labels"] || !viewModel) {
        return;
    }

    // Get the TFNTwitterStatus - it might be the viewModel itself or a property
    TFNTwitterStatus *status = nil;

    if ([viewModel isKindOfClass:%c(TFNTwitterStatus)]) {
        status = (TFNTwitterStatus *)viewModel;
    } else if ([viewModel respondsToSelector:@selector(status)]) {
        status = [viewModel performSelector:@selector(status)];
    }

    if (!status) {
        return;
    }

    // Get the tweet ID
    long long statusID = [status statusID];
    if (statusID <= 0) {
        return;
    }

    NSString *tweetIDStr = [NSString stringWithFormat:@"%lld", statusID];
    if (!tweetIDStr || tweetIDStr.length == 0) {
        return;
    }

    // Initialize tweet sources if needed
    if (!tweetSources) {
        tweetSources = [NSMutableDictionary dictionary];
    }

    // Fetch source if not cached
    if (!tweetSources[tweetIDStr]) {
        tweetSources[tweetIDStr] = @""; // Placeholder
        [TweetSourceHelper fetchSourceForTweetID:tweetIDStr];
    }

    // Update footer text immediately if we have the source
    NSString *sourceText = tweetSources[tweetIDStr];
    if (sourceText && sourceText.length > 0 && ![sourceText isEqualToString:@"Source Unavailable"] && ![sourceText isEqualToString:@""]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf BHT_updateFooterTextWithSource:sourceText tweetID:tweetIDStr];
            }
        });
    }
}

%new
- (void)BHT_handleSourceLabelTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }

    NSURL *url = [NSURL URLWithString:@"https://help.twitter.com/using-twitter/how-to-tweet#source-labels"];
    if (!url) {
        return;
    }

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [app openURL:url
             options:@{}
   completionHandler:nil];
    } else {
        [app openURL:url];
    }
}

%new
- (void)BHT_updateFooterTextWithSource:(NSString *)sourceText tweetID:(NSString *)tweetID {
    // Look for T1ConversationFooterItem in the view hierarchy
    __block id footerItem = nil;
    BH_EnumerateSubviewsRecursively(self, ^(UIView *view) {
        if (footerItem) return;

        // Check if this view has a footerItem property
        if ([view respondsToSelector:@selector(footerItem)]) {
            id item = [view performSelector:@selector(footerItem)];
            if (item && [item isKindOfClass:%c(T1ConversationFooterItem)]) {
                footerItem = item;
            }
        }
    });

    if (!footerItem || ![footerItem respondsToSelector:@selector(timeAgo)]) {
        return;
    }

    NSString *currentTimeAgo = [footerItem performSelector:@selector(timeAgo)];
    if (!currentTimeAgo || currentTimeAgo.length == 0) {
                return;
            }

    // Don't append if source is already there
    if ([currentTimeAgo containsString:sourceText] || [currentTimeAgo containsString:@"Twitter for"] || [currentTimeAgo containsString:@"via "]) {
        return;
    }

    // Create new timeAgo with source appended
    NSString *newTimeAgo = [NSString stringWithFormat:@"%@ · %@", currentTimeAgo, sourceText];

// Set the new timeAgo and hide view count
if ([footerItem respondsToSelector:@selector(setTimeAgo:)]) {
    [footerItem performSelector:@selector(setTimeAgo:) withObject:newTimeAgo];

    // Now update the footer text view to refresh the display
    id footerTextView = [self footerTextView];
    if (footerTextView && [footerTextView respondsToSelector:@selector(updateFooterTextView)]) {
        [footerTextView performSelector:@selector(updateFooterTextView)];
    }

    // Make the footer tappable to open the source label help page
    if ([footerTextView isKindOfClass:[UIView class]]) {
        UIView *footerView = (UIView *)footerTextView;
        footerView.userInteractionEnabled = YES;

NSNumber *alreadyAdded = objc_getAssociatedObject(footerView, &kBHTSourceTapAddedKey);
        if (![alreadyAdded boolValue]) {
            UITapGestureRecognizer *tap =
                [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(BHT_handleSourceLabelTap:)];
            [footerView addGestureRecognizer:tap];
objc_setAssociatedObject(footerView,
                         &kBHTSourceTapAddedKey,
                         @(YES),
                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}
}



%end
// MARK: Source Label using T1ConversationFooterTextView

%hook T1ConversationFooterTextView

- (void)updateFooterTextView {
    %orig;

    // Add source label to footer text view
    if ([BHTSettings boolForKey:@"restore_tweet_labels"] && self.viewModel) {
        @try {
            // Get the tweet object from the view model
            id tweetObject = nil;
            if ([self.viewModel respondsToSelector:@selector(tweet)]) {
                tweetObject = [self.viewModel performSelector:@selector(tweet)];
            } else if ([self.viewModel respondsToSelector:@selector(status)]) {
                tweetObject = [self.viewModel performSelector:@selector(status)];
            }

            if (tweetObject) {
                // Get tweet ID
                NSString *tweetIDStr = nil;
                @try {
                    id statusIDVal = [tweetObject valueForKey:@"statusID"];
                    if (statusIDVal && [statusIDVal respondsToSelector:@selector(longLongValue)] && [statusIDVal longLongValue] > 0) {
                        tweetIDStr = [statusIDVal stringValue];
                    }
                } @catch (NSException *e) {}

                if (!tweetIDStr || tweetIDStr.length == 0) {
                    @try {
                        tweetIDStr = [tweetObject valueForKey:@"rest_id"];
                        if (!tweetIDStr || tweetIDStr.length == 0) {
                            tweetIDStr = [tweetObject valueForKey:@"id_str"];
                        }
                        if (!tweetIDStr || tweetIDStr.length == 0) {
                            id genericID = [tweetObject valueForKey:@"id"];
                            if (genericID) tweetIDStr = [genericID description];
                        }
                    } @catch (NSException *e) {}
                }

                if (tweetIDStr && tweetIDStr.length > 0) {
                    // Initialize source tracking if needed
                    if (!tweetSources) tweetSources = [NSMutableDictionary dictionary];

                    // Fetch source if not already available
                    if (!tweetSources[tweetIDStr]) {
                        tweetSources[tweetIDStr] = @""; // Placeholder
                        [TweetSourceHelper fetchSourceForTweetID:tweetIDStr];
                    }

                    // Legacy source code removed
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[BHTwitter] Exception in T1ConversationFooterTextView updateFooterTextView: %@", e);
        }
    }
}

%end

%ctor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Initialize the concurrent queue for source label data access
        sourceLabelDataQueue = dispatch_queue_create("com.bandarhelal.bhtwitter.sourceLabelQueue", DISPATCH_QUEUE_CONCURRENT);
    });

    // Initialize dictionaries for Tweet Source Labels restoration
    dispatch_barrier_async(sourceLabelDataQueue, ^{
        if (!tweetSources)      tweetSources      = [NSMutableDictionary dictionary];
        if (!fetchTimeouts)     fetchTimeouts     = [NSMutableDictionary dictionary];
        if (!fetchRetries)      fetchRetries      = [NSMutableDictionary dictionary];
        if (!fetchPending)      fetchPending      = [NSMutableDictionary dictionary];
        if (!cookieCache)       cookieCache       = [NSMutableDictionary dictionary];
    });
    // These dictionaries are UI-related and should only be accessed on the main thread
    if (!viewToTweetID)     viewToTweetID     = [NSMutableDictionary dictionary];
    if (!viewInstances)     viewInstances     = [NSMutableDictionary dictionary];

    // Load cached cookies at initialization
    [TweetSourceHelper loadCachedCookies];

    %init;
}
