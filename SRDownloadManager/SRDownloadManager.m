//
//  SRDownloadManager.m
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadManager.h"

#define SRDownloadDirectory self.downloadedFilesDirectory ?: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] \
                                                               stringByAppendingPathComponent:NSStringFromClass([self class])]

#define SRFileName(URL) [URL lastPathComponent]

#define SRFilePath(URL) [SRDownloadDirectory stringByAppendingPathComponent:SRFileName(URL)]

#define SRFilesTotalLengthPlistPath [SRDownloadDirectory stringByAppendingPathComponent:@"FilesTotalLength.plist"]

@interface SRDownloadManager() <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;

@property (nonatomic, strong) NSMutableDictionary *downloadModels;

@end

@implementation SRDownloadManager

+ (instancetype)sharedManager {

    static SRDownloadManager *downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
    });
    return downloadManager;
}

- (NSURLSession *)urlSession {
    
    if (!_urlSession) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:self
                                               delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _urlSession;
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

- (NSMutableDictionary *)downloadModels {
    
    if (!_downloadModels) {
        _downloadModels = [NSMutableDictionary dictionary];
    }
    return _downloadModels;
}

#pragma mark - Download Actions

- (void)downloadFileOfURL:(NSURL *)URL
                    state:(void(^)(SRDownloadState state))state
                 progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
               completion:(void(^)(BOOL success, NSString *filePath, NSError *error))completion
{
    if (!URL) {
        return;
    }
    
    if ([self isDownloadCompletedOfURL:URL]) {
        if (state) {
            state(SRDownloadStateCompleted);
        }
        if (completion) {
            completion(YES, [self fileFullPathOfURL:URL], nil);
        }
        return;
    }
    
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (downloadModel) {
        if (downloadModel.dataTask.state == NSURLSessionTaskStateRunning) {
            [self suspendDownloadOfURL:URL];
        } else {
            [self resumeDownloadOfURL:URL];
        }
        return;
    }
    
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    [requestM setValue:[NSString stringWithFormat:@"bytes=%lld-", (long long int)[self hasDownloadedLength:URL]] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:requestM];
    dataTask.taskDescription = SRFileName(URL);
    
    downloadModel = [[SRDownloadModel alloc] init];
    downloadModel.dataTask = dataTask;
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:[self fileFullPathOfURL:URL] append:YES];
    downloadModel.URL = URL;
    downloadModel.state = state;
    downloadModel.progress = progress;
    downloadModel.completion = completion;
    self.downloadModels[dataTask.taskDescription] = downloadModel;
    
    [dataTask resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateRunning);
        }
    });
}

- (void)suspendDownloadOfURL:(NSURL *)URL {
    
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (!downloadModel) {
        return;
    }
    if (downloadModel.dataTask.state != NSURLSessionTaskStateRunning) {
        return;
    }
    [downloadModel.dataTask suspend];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateSuspended);
        }
    });
}

- (void)suspendAllDownloads {
    
    if (self.downloadModels.count == 0) {
        return;
    }
    NSArray *downloadModels = self.downloadModels.allValues;
    for (SRDownloadModel *downloadModel in downloadModels) {
        if (downloadModel.dataTask.state != NSURLSessionTaskStateRunning) {
            continue;
        }
        [downloadModel.dataTask suspend];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateSuspended);
            }
        });
    }
}

- (void)resumeDownloadOfURL:(NSURL *)URL {
    
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (!downloadModel) {
        return;
    }
    if (downloadModel.dataTask.state != NSURLSessionTaskStateSuspended) {
        return;
    }
    [downloadModel.dataTask resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateRunning);
        }
    });
}

- (void)resumeAllDownloads {
    
    if (self.downloadModels.count == 0) {
        return;
    }
    NSArray *downloadModels = self.downloadModels.allValues;
    for (SRDownloadModel *downloadModel in downloadModels) {
        if (downloadModel.dataTask.state != NSURLSessionTaskStateSuspended) {
            continue;
        }
        [downloadModel.dataTask resume];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateRunning);
            }
        });
    }
}

- (void)cancelDownloadOfURL:(NSURL *)URL {
    
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (!downloadModel) {
        return;
    }
    [downloadModel closeOutputStream];
    [downloadModel.dataTask cancel];
    [self.downloadModels removeObjectForKey:SRFileName(URL)];
}

- (void)cancelAllDownloads {
    
    if (self.downloadModels.count == 0) {
        return;
    }
    NSArray *downloadModels = self.downloadModels.allValues;
    for (SRDownloadModel *downloadModel in downloadModels) {
        [downloadModel closeOutputStream];
        [downloadModel.dataTask cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateCanceled);
            }
        });
    }
    [self.downloadModels removeAllObjects];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    SRDownloadModel *downloadModel = self.downloadModels[dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    
    [downloadModel openOutputStream];
    
    NSInteger thisTotalLength = response.expectedContentLength; // [response.allHeaderFields[@"Content-Length"] integerValue]
    NSInteger totalLength = thisTotalLength + [self hasDownloadedLength:downloadModel.URL];
    downloadModel.totalLength = totalLength;
    NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath] ?: [NSMutableDictionary dictionary];
    filesTotalLength[SRFileName(downloadModel.URL)] = @(totalLength);
    [filesTotalLength writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    SRDownloadModel *downloadModel = self.downloadModels[dataTask.taskDescription];
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
    
    SRDownloadModel *downloadModel = self.downloadModels[task.taskDescription];
    if (!downloadModel) {
        return;
    }
    
    [downloadModel closeOutputStream];
    [self.downloadModels removeObjectForKey:task.taskDescription];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isDownloadCompletedOfURL:downloadModel.URL]) {
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateCompleted);
            }
            if (downloadModel.completion) {
                downloadModel.completion(YES, [self fileFullPathOfURL:downloadModel.URL], error);
            }
            return;
        }
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateFailed);
        }
        if (downloadModel.completion) {
            downloadModel.completion(NO, nil, error);
        }
    });
}

#pragma mark - Assist Methods

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
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self fileFullPathOfURL:URL] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

#pragma mark - Public Methods

- (BOOL)isDownloadCompletedOfURL:(NSURL *)URL {
    
    NSInteger totalLength = [self totalLength:URL];
    if (totalLength != 0) {
        if (totalLength == [self hasDownloadedLength:URL]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)fileFullPathOfURL:(NSURL *)URL {
    
    return SRFilePath(URL);
}

- (CGFloat)fileHasDownloadedProgressOfURL:(NSURL *)URL {
    
    if ([self isDownloadCompletedOfURL:URL]) {
        return 1.0;
    }
    if ([self totalLength:URL] == 0) {
        return 0.0;
    }
    return 1.0 * [self hasDownloadedLength:URL] / [self totalLength:URL];
}

- (void)deleteFileOfURL:(NSURL *)URL {
    
    [self cancelDownloadOfURL:URL];
    
    NSMutableDictionary *filesTotalLenth = [NSMutableDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath];
    [filesTotalLenth removeObjectForKey:SRFileName(URL)];
    [filesTotalLenth writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self fileFullPathOfURL:URL];
    if (![fileManager fileExistsAtPath:filePath]) {
        return;
    }
    if ([fileManager removeItemAtPath:filePath error:nil]) {
        return;
    }
    NSLog(@"removeItemAtPath Failed: %@", filePath);
}

- (void)deleteAllFiles {
    
    [self cancelAllDownloads];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:SRDownloadDirectory error:nil];
    for (NSString *fileName in fileNames) {
        NSString *filePath = [SRDownloadDirectory stringByAppendingPathComponent:fileName];
        if ([fileManager removeItemAtPath:filePath error:nil]) {
            continue;
        }
        NSLog(@"removeItemAtPath Failed: %@", filePath);
    }
}

- (void)setDownloadedFilesDirectory:(NSString *)downloadedFilesDirectory {
    
    _downloadedFilesDirectory = downloadedFilesDirectory;
    
    if (!downloadedFilesDirectory) {
        return;
    }
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:downloadedFilesDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:downloadedFilesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

@end
