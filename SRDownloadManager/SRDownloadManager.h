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
 *  If you like it, please star it, thanks a lot.
 *  Github: https://github.com/guowilling/SRDownloadManager
 *
 *  Have Fun.
 */

#import <Foundation/Foundation.h>
#import "SRDownloadModel.h"

@interface SRDownloadManager : NSObject

/**
 The directory where the downloaded files are saved, default is Library/Caches/SRDownloadManager if not setted.
 */
@property (nonatomic, copy) NSString *downloadDirectory;

+ (instancetype)sharedManager;

- (void)download:(NSURL *)URL
           state:(void (^)(SRDownloadState state))state
        progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
      completion:(void (^)(BOOL isSuccess, NSString *filePath, NSError *error))completion;

- (BOOL)isCompleted:(NSURL *)URL;

- (NSString *)fileFullPath:(NSURL *)URL;

- (CGFloat)fileProgress:(NSURL *)URL;

- (void)deleteFile:(NSURL *)URL;

- (void)deleteAllFiles;

@end
