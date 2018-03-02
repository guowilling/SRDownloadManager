//
//  SRVideoDownloader.m
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/4/6.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRVideoDownloader.h"
#import <UIKit/UIKit.h>

#define SRVideosDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] \
                            stringByAppendingPathComponent:NSStringFromClass([self class])]

@interface SRVideoDownloader () <NSURLSessionDataDelegate>

@property (nonatomic, copy) NSString *tmpVideoPath;
@property (nonatomic, copy) NSString *cacheVideoPath;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, assign) NSInteger downloadedLength;
@property (nonatomic, assign) NSInteger expectedLength;

@property (nonatomic, copy) Completion completion;
@property (nonatomic, copy) Progress progress;

@end

@implementation SRVideoDownloader

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

+ (instancetype)sharedDownloader {
    static SRVideoDownloader *videoDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        videoDownloader = [[self alloc] init];
    });
    return videoDownloader;
}

- (instancetype)init {
    if (self = [super init]) {
        [self createVideosDirectory];
    }
    return self;
}

- (void)createVideosDirectory {
    NSString *videosDirectory = SRVideosDirectory;
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:videosDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:videosDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)querySandboxWithURL:(NSURL *)URL {
    NSString *videoName = URL.lastPathComponent;
    NSString *cachePath = [SRVideosDirectory stringByAppendingPathComponent:videoName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        return cachePath;
    }
    return nil;
}

- (void)downloadVideoOfURL:(NSURL *)URL progress:(Progress)progress completion:(Completion)completion {
    if (!URL) {
        return;
    }
    if (![URL.absoluteString containsString:@"http"] && ![URL.absoluteString containsString:@"https"]) {
        NSLog(@"It is not network video.");
        return;
    }
    self.progress = progress;
    self.completion = completion;
    
    NSString *videoName = URL.lastPathComponent;
    self.cacheVideoPath = [SRVideosDirectory stringByAppendingPathComponent:videoName];
    
    self.tmpVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.tmpVideoPath]) {
        self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.tmpVideoPath];
        self.downloadedLength = [self.fileHandle seekToEndOfFile];
    } else {
        [[NSFileManager defaultManager] createFileAtPath:self.tmpVideoPath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.tmpVideoPath];
        self.downloadedLength = 0;
    }
    
    NSMutableURLRequest *requeset = [NSMutableURLRequest requestWithURL:URL];
    [requeset setValue:[NSString stringWithFormat:@"bytes=%ld-", _downloadedLength] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:requeset];
    [dataTask resume];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSDictionary *allHeaderFields = [httpResponse allHeaderFields];
    NSString *contentRange = [allHeaderFields valueForKey:@"Content-Range"];
    self.expectedLength = [contentRange componentsSeparatedByString:@"/"].lastObject.integerValue;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.fileHandle writeData:data];
    
    self.downloadedLength += data.length;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progress) {
            self.progress(self.downloadedLength * 1.0 / self.expectedLength);
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        if (self.completion) {
            self.completion(nil, error);
        }
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completion) {
            self.completion(self.cacheVideoPath, nil);
        }
    });
    NSError *moveItemError;
    if (![[NSFileManager defaultManager] moveItemAtPath:self.tmpVideoPath toPath:self.cacheVideoPath error:&moveItemError]) {
        NSLog(@"moveItemAtPath error: %@", moveItemError);
    }
}

#pragma mark - Public Methods

- (void)cancelDownloadActions {
    [self.session invalidateAndCancel];
    [self setSession:nil];
}

- (void)clearCachedVideos {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:SRVideosDirectory]) {
        [fileManager removeItemAtPath:SRVideosDirectory error:nil];
        [self createVideosDirectory];
    }
}

@end
