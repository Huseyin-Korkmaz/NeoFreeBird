//
//  Download.m
//  NeoFreeBird
//
//  Original author: BandarHelal at 12/01/1442 AH
//

#import "Download.h"

// Remote filenames arrive with query strings and, occasionally, path separators.
// Keep the last path component (queries are dropped by -[NSURL lastPathComponent])
// and neutralise anything that can't live on disk so the move to tmp can't fail.
static NSString *SanitizedDownloadFileName(NSURL *url) {
    NSString *candidate = url.lastPathComponent;

    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:"];
    NSString *clean = [[candidate componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];

    if (clean.length == 0) {
        clean = [NSString stringWithFormat:@"%@.mp4", NSUUID.UUID.UUIDString];
    }
    return clean;
}

@interface Download () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation Download

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.waitsForConnectivity = YES;

        NSOperationQueue *delegateQueue = [NSOperationQueue new];
        delegateQueue.maxConcurrentOperationCount = 1;
        delegateQueue.name = @"com.neofreebird.download";

        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:delegateQueue];
    }
    return self;
}

- (void)downloadFileWithURL:(NSURL *)url {
    if (!url) {
        return;
    }

    self.fileName = SanitizedDownloadFileName(url);
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:url];
    [task resume];
}

#pragma mark - Delegate marshalling

- (void)notifyFailure:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        id<DownloadDelegate> delegate = weakSelf.delegate;
        if ([delegate respondsToSelector:@selector(downloadDidFailureWithError:)]) {
            [delegate downloadDidFailureWithError:error];
        }
    });
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (totalBytesExpectedToWrite <= 0) {
        return;
    }

    float progress = (float)((double)totalBytesWritten / (double)totalBytesExpectedToWrite);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        id<DownloadDelegate> delegate = weakSelf.delegate;
        if ([delegate respondsToSelector:@selector(downloadProgress:)]) {
            [delegate downloadProgress:progress];
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // The temporary file at `location` is removed as soon as this method returns,
    // so relocate it synchronously before handing a stable URL to the delegate.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *name = self.fileName.length ? self.fileName : [NSString stringWithFormat:@"%@.mp4", NSUUID.UUID.UUIDString];
    NSURL *stableURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:name];

    [fileManager removeItemAtURL:stableURL error:NULL];

    NSError *moveError = nil;
    if (![fileManager moveItemAtURL:location toURL:stableURL error:&moveError]) {
        [self notifyFailure:moveError];
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        id<DownloadDelegate> delegate = weakSelf.delegate;
        if ([delegate respondsToSelector:@selector(downloadDidFinish:Filename:)]) {
            [delegate downloadDidFinish:stableURL Filename:name];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self notifyFailure:error];
    }

    // Break the session's strong reference to this delegate once we're done.
    [session finishTasksAndInvalidate];
}

@end
