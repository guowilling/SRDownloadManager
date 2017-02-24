//
//  SRDownloadManager.m
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadManager.h"

#define SRDownloadDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] \
                              stringByAppendingPathComponent:NSStringFromClass([self class])]

#define SRFileName(URL) [URL lastPathComponent]

#define SRFilePath(URL) [SRDownloadDirectory stringByAppendingPathComponent:SRFileName(URL)]

#define SRFilesTotalLengthPlistPath [SRDownloadDirectory stringByAppendingPathComponent:@"FilesTotalLength.plist"]

@interface SRDownloadManager() <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *dataTasksDic;

@property (nonatomic, strong) NSMutableDictionary *downloadModelsDic;

@end

@implementation SRDownloadManager

+ (void)load {
    
    NSString *downloadDirectory = SRDownloadDirectory;
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:downloadDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (instancetype)sharedManager {
    
    static SRDownloadManager *downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
    });
    return downloadManager;
}

#pragma mark - Lazy Load

- (NSMutableDictionary *)dataTasksDic {
    
    if (!_dataTasksDic) {
        _dataTasksDic = [NSMutableDictionary dictionary];
    }
    return _dataTasksDic;
}

- (NSMutableDictionary *)downloadModelsDic {
    
    if (!_downloadModelsDic) {
        _downloadModelsDic = [NSMutableDictionary dictionary];
    }
    return _downloadModelsDic;
}

#pragma mark - Download Action

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
        NSURLSessionDataTask *dataTask = [self dataTask:URL];
        if (dataTask.state == NSURLSessionTaskStateRunning) {
            [self pauseDownload:URL];
        } else {
            [self startDownload:URL];
        }
        return;
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[[NSOperationQueue alloc] init]];
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    NSString *range = [NSString stringWithFormat:@"bytes=%lld-", (long long)[self hasDownloadedLength:URL]];
    [requestM setValue:range forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:requestM];
    NSUInteger taskIdentifier = arc4random() % 10000 + arc4random() % 10000;
    [dataTask setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    self.dataTasksDic[SRFileName(URL)] = dataTask;
    
    SRDownloadModel *downloadModel = [[SRDownloadModel alloc] init];
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:SRFilePath(URL) append:YES];
    downloadModel.URL = URL;
    downloadModel.state = state;
    downloadModel.progress = progress;
    downloadModel.completion = completion;
    self.downloadModelsDic[@(dataTask.taskIdentifier).stringValue] = downloadModel;

    [self startDownload:URL];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    SRDownloadModel *downloadModel = self.downloadModelsDic[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel.outputStream open];
    
    //NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + [self hasDownloadedLength:downloadModel.URL];
    NSInteger totalLength = response.expectedContentLength + [self hasDownloadedLength:downloadModel.URL];
    downloadModel.totalLength = totalLength;
    NSMutableDictionary *totalLengthDic = [NSMutableDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath] ?: [NSMutableDictionary dictionary];
    totalLengthDic[SRFileName(downloadModel.URL)] = @(totalLength);
    [totalLengthDic writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    SRDownloadModel *downloadModel = self.downloadModelsDic[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel.outputStream write:data.bytes maxLength:data.length];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.progress) {
            NSUInteger receivedSize = [self hasDownloadedLength:downloadModel.URL];
            NSUInteger expectedSize = downloadModel.totalLength;
            CGFloat progress = 1.0 * receivedSize / expectedSize;
            downloadModel.progress(receivedSize, expectedSize, progress);
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    SRDownloadModel *downloadModel = self.downloadModelsDic[@(task.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel closeOutputStream];
    [self.dataTasksDic removeObjectForKey:SRFileName(downloadModel.URL)];
    [self.downloadModelsDic removeObjectForKey:@(task.taskIdentifier).stringValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isCompleted:downloadModel.URL]) {
            if (downloadModel.completion) {
                downloadModel.completion(YES, SRFilePath(downloadModel.URL), error);
            }
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateCompleted);
            }
            return;
        }
        if (error) {
            if (downloadModel.completion) {
                downloadModel.completion(NO, nil, error);
            }
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateFailed);
            }
        }
    });
}

#pragma mark - Assist Methods

- (void)startDownload:(NSURL *)URL {
    
    NSURLSessionDataTask *dataTask = [self dataTask:URL];
    if (!dataTask) {
        return;
    }
    [dataTask resume];
    
    SRDownloadModel *downloadModel = self.downloadModelsDic[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateRunning);
        }
    });
}

- (void)pauseDownload:(NSURL *)URL {
    
    NSURLSessionDataTask *dataTask = [self dataTask:URL];
    if (!dataTask) {
        return;
    }
    [dataTask suspend];
    
    SRDownloadModel *downloadModel = self.downloadModelsDic[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateSuspended);
        }
    });
}

- (NSURLSessionDataTask *)dataTask:(NSURL *)URL {
    
    return self.dataTasksDic[SRFileName(URL)];
}

- (NSInteger)totalLength:(NSURL *)URL {
    
    NSDictionary *filesTotalLenthDic = [NSDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath];
    if (!filesTotalLenthDic) {
        return 0;
    }
    if (!filesTotalLenthDic[SRFileName(URL)]) {
        return 0;
    }
    return [filesTotalLenthDic[SRFileName(URL)] integerValue];
}

- (NSInteger)hasDownloadedLength:(NSURL *)URL {
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:SRFilePath(URL) error:nil];
    return [fileAttributes[NSFileSize] integerValue];
}

#pragma mark - Public Methods

- (BOOL)isCompleted:(NSURL *)URL {
    
    if ([self totalLength:URL] != 0) {
        if ([self totalLength:URL] == [self hasDownloadedLength:URL]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)fileFullPath:(NSURL *)URL {
    
    return SRFilePath(URL);
}

- (CGFloat)fileProgress:(NSURL *)URL {
    
    if ([self isCompleted:URL]) {
        return 1.0;
    }
    if ([self totalLength:URL] == 0) {
        return 0.0;
    }
    return 1.0 * [self hasDownloadedLength:URL] / [self totalLength:URL];
}

- (void)deleteFile:(NSURL *)URL {
    
    NSURLSessionDataTask *dataTask = [self dataTask:URL];
    SRDownloadModel *downloadModel = self.downloadModelsDic[@(dataTask.taskIdentifier).stringValue];
    [downloadModel closeOutputStream];
    [self.downloadModelsDic removeObjectForKey:@(dataTask.taskIdentifier).stringValue];
    [dataTask cancel];
    [self.dataTasksDic removeObjectForKey:SRFileName(URL)];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:SRFilePath(URL)]) {
        return;
    }
    
    BOOL flag = [fileManager removeItemAtPath:SRFilePath(URL) error:nil];
    if (!flag) {
        NSLog(@"removeItemAtPath Failed!");
    }
    
    NSMutableDictionary *filesTotalLenthDic = [NSMutableDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath];
    [filesTotalLenthDic removeObjectForKey:SRFileName(URL)];
    [filesTotalLenthDic writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
}

- (void)deleteAllFiles {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:SRDownloadDirectory error:nil];
    for (NSString *fileName in fileNames) {
        BOOL flag = [fileManager removeItemAtPath:[SRDownloadDirectory stringByAppendingPathComponent:fileName] error:nil];
        if (!flag) {
            NSLog(@"removeItemAtPath Failed!");
        }
    }
    
    NSArray *downloadModels = self.downloadModelsDic.allValues;
    for (SRDownloadModel *downloadModel in downloadModels) {
        [downloadModel closeOutputStream];
    }
    [self.downloadModelsDic removeAllObjects];
    
    NSArray *dataTasks = [self.dataTasksDic allValues];
    [dataTasks makeObjectsPerformSelector:@selector(cancel)];
    [self.dataTasksDic removeAllObjects];
}

@end
