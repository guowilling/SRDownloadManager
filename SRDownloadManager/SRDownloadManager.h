//
//  SRDownloadManager.h
//  SRDownloadManager
//
//  Created by https://github.com/guowilling on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRDownloadModel.h"

typedef NS_ENUM(NSInteger, SRWaitingQueueMode) {
    SRWaitingQueueModeFIFO,
    SRWaitingQueueModeLIFO
};

@interface SRDownloadManager : NSObject

/**
 The directory where downloaded files are cached, default is .../Library/Caches/SRDownloadManager if not setted.
 */
@property (nonatomic, copy) NSString *cacheFilesDirectory;

/**
 The count of max concurrent downloads, default is -1 which means no limit.
 */
@property (nonatomic, assign) NSInteger maxConcurrentCount;

/**
 The mode of waiting download queue, default is FIFO.
 */
@property (nonatomic, assign) SRWaitingQueueMode waitingQueueMode;

+ (instancetype)sharedManager;

/**
 Starts a file download action with URL, download state, download progress and download completion block.
 
 @param URL        The URL of the file which to be downloaded.
 @param destPath   The path to save the file after the download is completed, if pass nil file will be saved in default path.
 @param state      A block object to be executed when the download state changed.
 @param progress   A block object to be executed when the download progress changed.
 @param completion A block object to be executed when the download completion.
 */
- (void)download:(NSURL *)URL
        destPath:(NSString *)destPath
           state:(void (^)(SRDownloadState state))state
        progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
      completion:(void (^)(BOOL success, NSString *filePath, NSError *error))completion;

- (BOOL)isDownloadCompletedOfURL:(NSURL *)URL;

#pragma mark - Downloads

/**
 Suspend the download of the URL.
 */
- (void)suspendDownloadOfURL:(NSURL *)URL;

/**
 Suspend all downloads include which are downloading and waiting.
 */
- (void)suspendDownloads;

/**
 Resume the download of the URL.
 */
- (void)resumeDownloadOfURL:(NSURL *)URL;

/**
 Resume all downloads.
 */
- (void)resumeDownloads;

/**
 Cancle the download of the URL.
 */
- (void)cancelDownloadOfURL:(NSURL *)URL;

/**
 Cancle all downloads include which are downloading and waiting.
 */
- (void)cancelDownloads;

#pragma mark - Files

/**
 The full path of the file corresponding to the URL cached in the sandbox.
 */
- (NSString *)fileFullPathOfURL:(NSURL *)URL;

/**
 The progress of the file corresponding to the URL has been downloaded.
 */
- (CGFloat)hasDownloadedProgressOfURL:(NSURL *)URL;

/**
 Delete the file of the URL in the current cache files directory.
 */
- (void)deleteFileOfURL:(NSURL *)URL;

/**
 Delete all files in the current cache files directory.
 */
- (void)deleteFiles;

@end
