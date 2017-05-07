//
//  SRDownloadModel.h
//  SRDownloadManager
//
//  Created by https://github.com/guowilling on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SRDownloadState) {
    SRDownloadStateWaiting,
    SRDownloadStateRunning,
    SRDownloadStateSuspended,
    SRDownloadStateCanceled,
    SRDownloadStateCompleted,
    SRDownloadStateFailed
};

@interface SRDownloadModel : NSObject

@property (nonatomic, strong) NSOutputStream *outputStream; // write datas to the file

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSURL *URL;

@property (nonatomic, assign) NSInteger totalLength;

@property (nonatomic, copy) void (^state)(SRDownloadState state);

@property (nonatomic, copy) void (^progress)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);

@property (nonatomic, copy) void (^completion)(BOOL isSuccess, NSString *filePath, NSError *error);

- (void)openOutputStream;

- (void)closeOutputStream;

@end
