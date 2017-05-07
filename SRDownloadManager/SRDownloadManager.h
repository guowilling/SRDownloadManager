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
    SRWaitingQueueModeFILO
};

@interface SRDownloadManager : NSObject

/**
 The directory where the downloaded files are saved, default is .../Library/Caches/SRDownloadManager if not setted.
 */
@property (nonatomic, copy) NSString *saveFilesDirectory;

/**
 The count of max concurrent downloads, default is -1 which means no limit.
 */
@property (nonatomic, assign) NSInteger maxConcurrentCount;

/**
 The mode of waiting for download queue, default is FIFO.
 */
@property (nonatomic, assign) SRWaitingQueueMode waitingQueueMode;

+ (instancetype)sharedManager;

/**
 Starts a file download action with URL, download state, download progress and download completion block.

 @param URL        The URL of the file which to be downloaded.
 @param state      A block object to be executed when the download state changed.
 @param progress   A block object to be executed when the download progress changed.
 @param completion A block object to be executed when the download completion.
 */
- (void)downloadURL:(NSURL *)URL
              state:(void (^)(SRDownloadState state))state
           progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
         completion:(void (^)(BOOL success, NSString *filePath, NSError *error))completion;

- (BOOL)isDownloadCompletedOfURL:(NSURL *)URL;

#pragma mark - Downloads

- (void)suspendDownloadOfURL:(NSURL *)URL;
- (void)suspendAllDownloads;

- (void)resumeDownloadOfURL:(NSURL *)URL;
- (void)resumeAllDownloads;

- (void)cancelDownloadOfURL:(NSURL *)URL;
- (void)cancelAllDownloads;

#pragma mark - Files

- (NSString *)fileFullPathOfURL:(NSURL *)URL;

- (CGFloat)fileHasDownloadedProgressOfURL:(NSURL *)URL;

- (void)deleteFile:(NSString *)fileName;
- (void)deleteFileOfURL:(NSURL *)URL;
- (void)deleteAllFiles;

@end
