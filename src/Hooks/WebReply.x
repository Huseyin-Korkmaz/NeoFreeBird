//
//  WebReply.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Open reply in webview

static TFNTwitterStatus *BHT_statusFromObject(id object) {
    if (!object) {
        return nil;
    }

    if ([object isKindOfClass:%c(TFNTwitterStatus)]) {
        return (TFNTwitterStatus *)object;
    }

    @try {
        id tweet = [object valueForKey:@"tweet"];
        if ([tweet isKindOfClass:%c(TFNTwitterStatus)]) {
            return (TFNTwitterStatus *)tweet;
        }
    } @catch (__unused NSException *exception) {}

    @try {
        id status = [object valueForKey:@"status"];
        if ([status isKindOfClass:%c(TFNTwitterStatus)]) {
            return (TFNTwitterStatus *)status;
        }
    } @catch (__unused NSException *exception) {}

    return nil;
}

static const void *BHTKeepReplyInWebViewKey = &BHTKeepReplyInWebViewKey;
static const void *BHTReplyWebViewDismissingKey = &BHTReplyWebViewDismissingKey;

// Injected into the reply webview via -evaluateJavaScript
// Grabs the ID of the new post
static NSString *const BHTReplyCaptureScript =
    @"(function(){"
    "if(window.__bhtReplyHook)return;window.__bhtReplyHook=true;"
    "var save=function(j){try{if(j&&j.data){"
    "var r=(j.data.create_tweet&&j.data.create_tweet.tweet_results&&j.data.create_tweet.tweet_results.result)||"
    "(j.data.notetweet_create&&j.data.notetweet_create.tweet_results&&j.data.notetweet_create.tweet_results.result);"
    "if(r&&r.rest_id)sessionStorage.setItem('__bhtNewReply',String(r.rest_id));}}catch(e){}};"
    "var isCreate=function(u){return typeof u==='string'&&u.indexOf('CreateTweet')!==-1;};"
    "var of=window.fetch;"
    "if(of){window.fetch=function(){var a=arguments;var u=(a[0]&&a[0].url)||a[0];"
    "return of.apply(this,a).then(function(res){try{if(isCreate(u))res.clone().json().then(save).catch(function(){});}catch(e){}return res;});};}"
    "var oo=XMLHttpRequest.prototype.open;var os=XMLHttpRequest.prototype.send;"
    "XMLHttpRequest.prototype.open=function(m,u){this.__bhtURL=u;return oo.apply(this,arguments);};"
    "XMLHttpRequest.prototype.send=function(){var x=this;try{if(isCreate(x.__bhtURL)){"
    "x.addEventListener('load',function(){try{save(JSON.parse(x.responseText));}catch(e){}});}}catch(e){}return os.apply(this,arguments);};"
    "})();";

static NSString *const BHTReplyReadScript =
    @"(function(){var v=sessionStorage.getItem('__bhtNewReply')||'';sessionStorage.removeItem('__bhtNewReply');return v;})();";

static void BHT_openStatusNatively(NSString *statusID) {
    if (statusID.length == 0) {
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://status?id=%@", statusID]];
    if (!url) {
        return;
    }

    id delegate = [UIApplication sharedApplication].delegate;
    if ([delegate respondsToSelector:@selector(openURL:options:)]) {
        ((void (*)(id, SEL, id, id))objc_msgSend)(delegate, @selector(openURL:options:), url, @{});
    }
}

static void BHT_showPostSentAlert(NSString *statusID) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = topMostController();
        if (!top) {
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"COMPOSITION_COMPLETE_SENDING_TWEET_TOAST_NOTIFICATION_MESSAGE"]
                                                                      message:nil
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"DM_MESSAGE_ACTION_OPEN_GENERIC_TITLE"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            BHT_openStatusNatively(statusID);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:[[BHTBundle sharedBundle] localizedTwitterStringForKey:@"DISMISS_LABEL"] style:UIAlertActionStyleCancel handler:nil]];
        [top presentViewController:alert animated:YES completion:nil];
    });
}

static BOOL BHT_openAuthenticatedTweetWebView(NSString *statusID) {
    if (statusID.length == 0) {
        return NO;
    }

    NSString *urlString = [NSString stringWithFormat:@"https://x.com/intent/tweet?in_reply_to=%@", statusID];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return NO;
    }

    Class webViewControllerClass = %c(T1WebViewController);
    SEL initSel = @selector(initWithRootURL:account:shouldAuthenticate:shouldPresentAsNativePage:sourceStatus:scribeComponent:scribeParameters:);
    if (!webViewControllerClass || ![webViewControllerClass instancesRespondToSelector:initSel]) {
        return NO;
    }

    id account = BHT_accountForAuthenticatedWebView();
    if (!account) {
        return NO;
    }

    UIViewController *presentingController = topMostController();
    if (!presentingController) {
        return NO;
    }

    T1WebViewController *webViewController =
        [[webViewControllerClass alloc] initWithRootURL:url
                                                account:account
                                     shouldAuthenticate:YES
                              shouldPresentAsNativePage:NO
                                           sourceStatus:nil
                                        scribeComponent:nil
                                       scribeParameters:nil];
    if (!webViewController) {
        return NO;
    }

    // Mark this instance so our -doesURLResultTypeOpenInWebview: and -setCurrentURL:
    // hooks know to keep the reply in-webview and auto-close it on /home.
    objc_setAssociatedObject(webViewController, BHTKeepReplyInWebViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    Class navigationControllerClass = NSClassFromString(@"T1WebNavigationController")
        ?: %c(TFNNavigationController)
        ?: UINavigationController.class;
    UINavigationController *modalNavigationController = [[navigationControllerClass alloc] initWithRootViewController:webViewController];

    [presentingController presentViewController:modalNavigationController animated:YES completion:nil];

    return YES;
}

// In 12.3 the inline reply button is a Swift TTAStatusInlineActionButton with no
// dedicated ObjC subclass; every inline reply tap funnels through this single event
// handler, whose originalStatus argument is the TFNTwitterStatus being replied to.
%hook T1StatusViewInlineActionTapEventHandler
- (void)performReplyActionWithAccount:(__unsafe_unretained id)account
                                event:(__unsafe_unretained id)event
                           controller:(__unsafe_unretained id)controller
                        scribeContext:(__unsafe_unretained id)scribeContext
                        scribeElement:(__unsafe_unretained id)scribeElement
                           parameters:(__unsafe_unretained id)parameters
                       originalStatus:(__unsafe_unretained TFNTwitterStatus *)originalStatus {
    if (![BHTSettings boolForKey:@"reply_in_webview"]) {
        return %orig;
    }

    if (![originalStatus respondsToSelector:@selector(statusID)]) {
        return %orig;
    }

    NSInteger statusID = originalStatus.statusID;
    if (statusID <= 0) {
        return %orig;
    }

    NSString *statusIDString = @(statusID).stringValue;
    if (!BHT_openAuthenticatedTweetWebView(statusIDString)) {
        return %orig;
    }
}
%end

%hook T1PersistentComposeViewController
- (void)persistentComposeViewDidTap:(id)composeView {
    if (![BHTSettings boolForKey:@"reply_in_webview"]) {
        return %orig;
    }

    TFNTwitterStatus *status = BHT_statusFromObject(self.statusViewModel);
    NSInteger statusID = status.statusID;
    if (statusID <= 0) {
        return %orig;
    }

    NSString *statusIDString = @(statusID).stringValue;
    if (!BHT_openAuthenticatedTweetWebView(statusIDString)) {
        return %orig;
    }
}
%end

%hook T1WebViewController
- (void)didFinishLoadingWithError:(id)error {
    %orig;

    BHT_maybeHandleHarvestWebView(self);

    if (!objc_getAssociatedObject(self, BHTKeepReplyInWebViewKey)) {
        return;
    }

    WKWebView *webView = [self webView];
    if ([webView isKindOfClass:%c(WKWebView)]) {
        [webView evaluateJavaScript:BHTReplyCaptureScript completionHandler:nil];
    }
}

- (BOOL)doesURLResultTypeOpenInWebview:(long long)resultType {
    if (objc_getAssociatedObject(self, BHTKeepReplyInWebViewKey)) {
        return YES;
    }
    return %orig;
}

- (void)setCurrentURL:(NSURL *)url {
    %orig;

    if (!objc_getAssociatedObject(self, BHTKeepReplyInWebViewKey) || ![url.path isEqualToString:@"/home"]) {
        return;
    }

    // setCurrentURL: can fire more than once for the same navigation; only act once.
    if (objc_getAssociatedObject(self, BHTReplyWebViewDismissingKey)) {
        return;
    }
    objc_setAssociatedObject(self, BHTReplyWebViewDismissingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    __weak T1WebViewController *weakSelf = self;

    void (^finish)(NSString *) = ^(NSString *newReplyID) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (newReplyID.length > 0) {
                BHT_showPostSentAlert(newReplyID);
            }
        }];
    };

    WKWebView *webView = [self webView];
    if ([webView isKindOfClass:%c(WKWebView)]) {
        [webView evaluateJavaScript:BHTReplyReadScript completionHandler:^(id result, NSError *jsError) {
            NSString *newReplyID = [result isKindOfClass:[NSString class]] ? (NSString *)result : nil;
            finish(newReplyID);
        }];
    } else {
        finish(nil);
    }
}
%end
