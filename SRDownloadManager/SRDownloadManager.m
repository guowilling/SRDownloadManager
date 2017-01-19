//
//  SRDownloadManager.m
//  SRDownloadManagerDemo
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadManager.h"

#define SRCacheDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:NSStringFromClass([self class])]

#define SRFileName(URL) URL.lastPathComponent

#define SRFileFullPath(URL) [SRCacheDirectory stringByAppendingPathComponent:SRFileName(URL)]

static SRDownloadManager *downloadManager;

@interface SRDownloadManager() <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *dataTasks;

@property (nonatomic, strong) NSMutableDictionary *downloadModels;

@end

@implementation SRDownloadManager

+ (void)load {
    
    NSString *cacheDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
                                stringByAppendingPathComponent:NSStringFromClass([self class])];
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Lazy Load

- (NSMutableDictionary *)dataTasks {
    
    if (!_dataTasks) {
        _dataTasks = [NSMutableDictionary dictionary];
    }
    return _dataTasks;
}

- (NSMutableDictionary *)downloadModels {
    
    if (!_downloadModels) {
        _downloadModels = [NSMutableDictionary dictionary];
    }
    return _downloadModels;
}

#pragma mark - Singleton

+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
    });
    return downloadManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [super allocWithZone:zone];
    });
    return downloadManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    
    return downloadManager;
}

- (void)download:(NSURL *)URL
           state:(void(^)(SRDownloadState state))state
        progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *error))completion
{
    if (!URL) {
        return;
    }
    
    if ([self isCompleted:URL]) {
        if (state) {
            state(SRDownloadStateCompleted);
        }
        return;
    }
    
    if ([self dataTask:URL]) {
        NSURLSessionDataTask *task = [self dataTask:URL];
        if (task.state == NSURLSessionTaskStateRunning) {
            [self pauseDownload:URL];
        } else {
            [self startDownload:URL];
        }
        return;
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[[NSOperationQueue alloc] init]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSString *range = [NSString stringWithFormat:@"bytes=%lld-", (long long)[self URLHasDownloadedLength:URL]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % 10000 + arc4random() % 10000;
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    self.dataTasks[SRFileName(URL)] = task;
    
    SRDownloadModel *downloadModel = [[SRDownloadModel alloc] init];
    downloadModel.URL = URL;
    downloadModel.state = state;
    downloadModel.progress = progress;
    downloadModel.completion = completion;
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:SRFileFullPath(URL.absoluteString) append:YES];
    self.downloadModels[@(task.taskIdentifier).stringValue] = downloadModel;
    
    [self startDownload:URL];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel.outputStream open];
    
    //[response.allHeaderFields[@"Content-Length"] integerValue]
    NSInteger totalLength = response.expectedContentLength + [self URLHasDownloadedLength:downloadModel.URL];
    downloadModel.totalLength = totalLength;
    NSMutableDictionary *totalLengthDic = [NSMutableDictionary dictionaryWithContentsOfFile:[self filesTotalLengthPlistPath]] ?: [NSMutableDictionary dictionary];
    totalLengthDic[SRFileName(downloadModel.URL)] = @(totalLength);
    [totalLengthDic writeToFile:[self filesTotalLengthPlistPath] atomically:YES];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel.outputStream write:data.bytes maxLength:data.length];
    
    if (downloadModel.progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger receivedSize = [self URLHasDownloadedLength:downloadModel.URL];
            NSUInteger expectedSize = downloadModel.totalLength;
            CGFloat progress = 1.0 * receivedSize / expectedSize;
            downloadModel.progress(receivedSize, expectedSize, progress);
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    SRDownloadModel *downloadModel = self.downloadModels[@(task.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel closeOutputStream];
    
    [self.dataTasks removeObjectForKey:SRFileName(downloadModel.URL)];
    [self.downloadModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
    if (downloadModel.state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self isCompleted:downloadModel.URL]) {
                if (downloadModel.completion) {
                    downloadModel.completion(YES, [self fileFullPath:downloadModel.URL], error);
                }
                if (downloadModel.state) {
                    downloadModel.state(SRDownloadStateCompleted);
                }
            } else if (error) {
                if (downloadModel.completion) {
                    downloadModel.completion(NO, nil, error);
                }
                if (downloadModel.state) {
                    downloadModel.state(SRDownloadStateFailed);
                }
            }
        });
    }
}

#pragma mark - Assist Methods

- (void)startDownload:(NSURL *)URL {
    
    NSURLSessionDataTask *task = [self dataTask:URL];
    if (!task) {
        return;
    }
    [task resume];
    
    SRDownloadModel *downloadModel = self.downloadModels[@(task.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    if (downloadModel.state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.state(SRDownloadStateRunning);
        });
    }
}

- (void)pauseDownload:(NSURL *)URL {
    
    NSURLSessionDataTask *task = [self dataTask:URL];
    if (!task) {
        return;
    }
    [task suspend];
    
    SRDownloadModel *downloadModel = self.downloadModels[@(task.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    if (downloadModel.state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.state(SRDownloadStateSuspended);
        });
    }
}

- (NSURLSessionDataTask *)dataTask:(NSURL *)URL {
    
    return self.dataTasks[SRFileName(URL)];
}

- (NSString *)filesTotalLengthPlistPath {
    
    return [SRCacheDirectory stringByAppendingPathComponent:@"FilesTotalLength.plist"];
}

- (NSInteger)totalLength:(NSURL *)URL {
    
    NSDictionary *totalLengthDic = [NSDictionary dictionaryWithContentsOfFile:[self filesTotalLengthPlistPath]];
    if (!totalLengthDic) {
        return 0;
    }
    if (!totalLengthDic[SRFileName(URL)]) {
        return 0;
    }
    return [totalLengthDic[SRFileName(URL)] integerValue];
}

- (NSInteger)URLHasDownloadedLength:(NSURL *)URL {
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:SRFileFullPath(URL) error:nil];
    return [fileAttributes[NSFileSize] integerValue];
}

#pragma mark - Public Methods

- (BOOL)isCompleted:(NSURL *)URL {
    
    if ([self totalLength:URL] != 0) {
        if ([self totalLength:URL] == [self URLHasDownloadedLength:URL]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)fileFullPath:(NSURL *)URL {
    
    return SRFileFullPath(URL);
}

- (CGFloat)progress:(NSURL *)URL {
    
    if ([self isCompleted:URL]) {
        return 1.0;
    }
    
    if ([self totalLength:URL] == 0) {
        return 0.0;
    }
    
    return 1.0 * [self URLHasDownloadedLength:URL] / [self totalLength:URL];
}

- (void)deleteFile:(NSURL *)URL {
    
    [self.dataTasks removeObjectForKey:SRFileName(URL)];
    [self.downloadModels removeObjectForKey:@([self dataTask:URL].taskIdentifier).stringValue];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:SRFileFullPath(URL)]) {
        return;
    }
    
    [fileManager removeItemAtPath:SRFileFullPath(URL) error:nil];
    NSMutableDictionary *totalLengthDic = [NSMutableDictionary dictionaryWithContentsOfFile:[self filesTotalLengthPlistPath]];
    [totalLengthDic removeObjectForKey:SRFileName(URL)];
    [totalLengthDic writeToFile:[self filesTotalLengthPlistPath] atomically:YES];
}

- (void)deleteAllFiles {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:SRCacheDirectory]) {
        return;
    }
    [fileManager removeItemAtPath:SRCacheDirectory error:nil];
    // Must create cache directory again or it will download fail if have not restart app.
    [fileManager createDirectoryAtPath:SRCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    
    if ([fileManager fileExistsAtPath:[self filesTotalLengthPlistPath]]) {
        [fileManager removeItemAtPath:[self filesTotalLengthPlistPath] error:nil];
    }
    
    NSArray *dataTasks = [self.dataTasks allValues];
    [dataTasks makeObjectsPerformSelector:@selector(cancel)];
    [self.dataTasks removeAllObjects];
    
    for (SRDownloadModel *downloadModel in [self.downloadModels allValues]) {
        [downloadModel.outputStream close];
    }
    [self.downloadModels removeAllObjects];
}

@end
