//
//  BHDownload.h
//  NeoFreeBird
//
//  Original author: BandarHelal at 12/01/1442 AH
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BHDownloadDelegate <NSObject>
@optional
- (void)downloadProgress:(float)progress;
- (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName;
- (void)downloadDidFailureWithError:(NSError *)error;
@end

// Thin NSURLSession wrapper that downloads a single remote file to a stable
// location in the temporary directory and reports progress/completion on the
// main queue. One instance drives one download.
@interface BHDownload : NSObject

@property (nonatomic, weak, nullable) id<BHDownloadDelegate> delegate;
@property (nonatomic, copy, nullable) NSString *fileName;

- (void)downloadFileWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
