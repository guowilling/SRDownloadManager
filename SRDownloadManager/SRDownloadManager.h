//
//  SRDownloadManager.h
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

/**
 *  If you have any question, submit an issue or contact me.
 *  QQ: 1990991510
 *  Email: guowilling@qq.com
 *
 *  If this repo helps you, please give it a star.
 *  Github: https://github.com/guowilling/SRDownloadManager
 *
 *  Have Fun.
 */

#import <Foundation/Foundation.h>
#import "SRDownloadModel.h"

@interface SRDownloadManager : NSObject

/**
 The directory where the downloaded files are saved, default is .../Library/Caches/SRDownloadManager if not setted.
 */
@property (nonatomic, copy) NSString *downloadedFilesDirectory;

+ (instancetype)sharedManager;

- (void)downloadFileOfURL:(NSURL *)URL
                    state:(void (^)(SRDownloadState state))state
                 progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
               completion:(void (^)(BOOL success, NSString *filePath, NSError *error))completion;

- (BOOL)isDownloadCompletedOfURL:(NSURL *)URL;

- (NSString *)fileFullPathOfURL:(NSURL *)URL;

- (CGFloat)fileHasDownloadedProgressOfURL:(NSURL *)URL;

- (void)deleteFileOfURL:(NSURL *)URL;
- (void)deleteAllFiles;

- (void)suspendDownloadOfURL:(NSURL *)URL;
- (void)suspendAllDownloads;

- (void)resumeDownloadOfURL:(NSURL *)URL;
- (void)resumeAllDownloads;

- (void)cancelDownloadOfURL:(NSURL *)URL;
- (void)cancelAllDownloads;

@end
