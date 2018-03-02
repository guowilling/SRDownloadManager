//
//  SRVideoDownloader.h
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/4/6.
//  Copyright © 2017年 SR. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^Progress)(CGFloat progress);
typedef void (^Completion)(NSString *cacheVideoPath, NSError *error);

@interface SRVideoDownloader : NSObject

+ (instancetype)sharedDownloader;

- (NSString *)querySandboxWithURL:(NSURL *)URL;

- (void)downloadVideoOfURL:(NSURL *)URL progress:(Progress)progress completion:(Completion)completion;

- (void)cancelDownloadActions;

- (void)clearCachedVideos;

@end
