//
//  SRDownloadManager.m
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadManager.h"

#define SRDownloadDirectory self.downloadDirectory ?: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] \
                                                        stringByAppendingPathComponent:NSStringFromClass([self class])]

#define SRFileName(URL) [URL lastPathComponent]

#define SRFilePath(URL) [SRDownloadDirectory stringByAppendingPathComponent:SRFileName(URL)]

#define SRFilesTotalLengthPlistPath [SRDownloadDirectory stringByAppendingPathComponent:@"FilesTotalLength.plist"]

#define SRDataTaskID (arc4random() % 1000000)

@interface SRDownloadManager() <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *dataTasks;

@property (nonatomic, strong) NSMutableDictionary *downloadModels;

@end

@implementation SRDownloadManager

//+ (void)load {
//    
//    NSString *downloadDirectory = SRDownloadDirectory;
//    BOOL isDirectory = NO;
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    BOOL isExists = [fileManager fileExistsAtPath:downloadDirectory isDirectory:&isDirectory];
//    if (!isExists || !isDirectory) {
//        [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//}

+ (instancetype)sharedManager {

    static SRDownloadManager *downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
    });
    return downloadManager;
}

- (instancetype)init {
    
    if (self = [super init]) {
        NSString *downloadDirectory = SRDownloadDirectory;
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isExists = [fileManager fileExistsAtPath:downloadDirectory isDirectory:&isDirectory];
        if (!isExists || !isDirectory) {
            [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
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
    
    NSURLSessionDataTask *dataTask = [self dataTask:URL];
    if (dataTask) {
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
    [requestM setValue:[NSString stringWithFormat:@"bytes=%lld-", (long long)[self hasDownloadedLength:URL]] forHTTPHeaderField:@"Range"];
    dataTask = [session dataTaskWithRequest:requestM];
    [dataTask setValue:@(SRDataTaskID) forKeyPath:@"taskIdentifier"]; // taskIdentifier property is readonly we set it through KVC.
    self.dataTasks[SRFileName(URL)] = dataTask;
    
    SRDownloadModel *downloadModel = [[SRDownloadModel alloc] init];
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:SRFilePath(URL) append:YES];
    downloadModel.URL = URL;
    downloadModel.state = state;
    downloadModel.progress = progress;
    downloadModel.completion = completion;
    self.downloadModels[@(dataTask.taskIdentifier).stringValue] = downloadModel;
    
    [dataTask resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateRunning);
        }
    });
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel openOutputStream];
    
    //NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + [self hasDownloadedLength:downloadModel.URL];
    NSInteger totalLength = response.expectedContentLength + [self hasDownloadedLength:downloadModel.URL];
    downloadModel.totalLength = totalLength;
    NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath] ?: [NSMutableDictionary dictionary];
    filesTotalLength[SRFileName(downloadModel.URL)] = @(totalLength);
    [filesTotalLength writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
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
    
    SRDownloadModel *downloadModel = self.downloadModels[@(task.taskIdentifier).stringValue];
    if (!downloadModel) {
        return;
    }
    [downloadModel closeOutputStream];
    [self.dataTasks removeObjectForKey:SRFileName(downloadModel.URL)];
    [self.downloadModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
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
        if (downloadModel.completion) {
            downloadModel.completion(NO, nil, error);
        }
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateFailed);
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
    
    SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
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
    
    SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
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
    
    return self.dataTasks[SRFileName(URL)];
}

- (NSInteger)totalLength:(NSURL *)URL {
    
    NSDictionary *filesTotalLenth = [NSDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath];
    if (!filesTotalLenth) {
        return 0;
    }
    if (!filesTotalLenth[SRFileName(URL)]) {
        return 0;
    }
    return [filesTotalLenth[SRFileName(URL)] integerValue];
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
    if (dataTask) {
        SRDownloadModel *downloadModel = self.downloadModels[@(dataTask.taskIdentifier).stringValue];
        if (downloadModel) {
            [downloadModel closeOutputStream];
            [self.downloadModels removeObjectForKey:@(dataTask.taskIdentifier).stringValue];
        }
        [dataTask cancel];
        [self.dataTasks removeObjectForKey:SRFileName(URL)];
    }
    
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
    
    if (self.downloadModels.count > 0) {
        NSArray *downloadModels = self.downloadModels.allValues;
        for (SRDownloadModel *downloadModel in downloadModels) {
            [downloadModel closeOutputStream];
        }
        [self.downloadModels removeAllObjects];
    }
    
    if (self.dataTasks.count > 0) {
        NSArray *dataTasks = [self.dataTasks allValues];
        [dataTasks makeObjectsPerformSelector:@selector(cancel)];
        [self.dataTasks removeAllObjects];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:SRDownloadDirectory error:nil];
    for (NSString *fileName in fileNames) {
        BOOL flag = [fileManager removeItemAtPath:[SRDownloadDirectory stringByAppendingPathComponent:fileName] error:nil];
        if (!flag) {
            NSLog(@"removeItemAtPath Failed!");
        }
    }
}

- (void)setDownloadDirectory:(NSString *)downloadDirectory {
    
    _downloadDirectory = downloadDirectory;
    
    if (!downloadDirectory) {
        return;
    }
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:downloadDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

@end
