//
//  SRDownloadManager.m
//  SRDownloadManager
//
//  Created by https://github.com/guowilling on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadManager.h"

#define SRDownloadDirectory self.saveFilesDirectory ?: [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject \
stringByAppendingPathComponent:NSStringFromClass([self class])]

#define SRFileName(URL) [URL lastPathComponent] // use URL's last path component as the file's name

#define SRFilePath(URL) [SRDownloadDirectory stringByAppendingPathComponent:SRFileName(URL)]

#define SRFilesTotalLengthPlistPath [SRDownloadDirectory stringByAppendingPathComponent:@"SRFilesTotalLength.plist"]

@interface SRDownloadManager() <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *downloadSession;

@property (nonatomic, strong) NSMutableDictionary *downloadModels; // a dictionary contains downloading and waiting models

@property (nonatomic, strong) NSMutableArray *downloadingModels; // a array contains models which are downloading now

@property (nonatomic, strong) NSMutableArray *waitingModels; // a array contains models which are waiting for download

@property (nonatomic, strong) NSMutableDictionary *filesTotalLengthPlist;

@end

@implementation SRDownloadManager

#pragma mark - Lazy Load

- (NSURLSession *)downloadSession {
    if (!_downloadSession) {
        _downloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                         delegate:self
                                                    delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _downloadSession;
}

- (NSMutableDictionary *)downloadModels {
    if (!_downloadModels) {
        _downloadModels = [NSMutableDictionary dictionary];
    }
    return _downloadModels;
}

- (NSMutableArray *)downloadingModels {
    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}

- (NSMutableArray *)waitingModels {
    if (!_waitingModels) {
        _waitingModels = [NSMutableArray array];
    }
    return _waitingModels;
}

- (NSMutableDictionary *)filesTotalLengthPlist {
    if (!_filesTotalLengthPlist) {
        _filesTotalLengthPlist = [NSMutableDictionary dictionaryWithContentsOfFile:SRFilesTotalLengthPlistPath];
        if (!_filesTotalLengthPlist) {
            _filesTotalLengthPlist = [NSMutableDictionary dictionary];
        }
    }
    return _filesTotalLengthPlist;
}

#pragma mark - Main Methods

+ (instancetype)sharedManager {
    static SRDownloadManager *downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
        downloadManager.maxConcurrentCount = -1;
        downloadManager.waitingQueueMode = SRWaitingQueueModeFIFO;
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

- (void)downloadURL:(NSURL *)URL
           destPath:(NSString *)destPath
              state:(void (^)(SRDownloadState state))state
           progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
         completion:(void (^)(BOOL success, NSString *filePath, NSError *error))completion
{
    NSAssert(URL != nil, @"URL can not be nil, please pass the resource's URL which you want to download");
    if ([self isDownloadCompletedOfURL:URL]) { // if this URL has been downloaded
        if (state) {
            state(SRDownloadStateCompleted);
        }
        if (completion) {
            completion(YES, [self fileFullPathOfURL:URL], nil);
        }
        return;
    }
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (downloadModel) { // if the download model of this URL has been added in downloadModels
        return;
    }
    
    // Range:
    // bytes=x-y ==  x byte ~ y byte
    // bytes=x-  ==  x byte ~ end
    // bytes=-y  ==  head ~ y byte
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    [requestM setValue:[NSString stringWithFormat:@"bytes=%ld-", [self hasDownloadedLength:URL]] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [self.downloadSession dataTaskWithRequest:requestM];
    dataTask.taskDescription = SRFileName(URL);
    
    // init a SRDownloadModel object
    downloadModel = [[SRDownloadModel alloc] init];
    downloadModel.dataTask = dataTask;
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:[self fileFullPathOfURL:URL] append:YES];
    downloadModel.URL = URL;
    downloadModel.destPath = destPath;
    downloadModel.state = state;
    downloadModel.progress = progress;
    downloadModel.completion = completion;
    self.downloadModels[dataTask.taskDescription] = downloadModel;
    
    SRDownloadState downloadState;
    if ([self canResumeDownload]) {
        [self.downloadingModels addObject:downloadModel];
        [dataTask resume];
        downloadState = SRDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = SRDownloadStateWaiting;
    }
    if (downloadModel.state) {
        downloadModel.state(downloadState);
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
    SRDownloadModel *downloadModel = self.downloadModels[dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    [downloadModel openOutputStream];
    
    // response.expectedContentLength == [HTTPResponse.allHeaderFields[@"Content-Length"] integerValue]
    // response.expectedContentLength + [self hasDownloadedLength:downloadModel.URL] == [[HTTPResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"].lastObject integerValue]
    NSInteger totalLength = response.expectedContentLength + [self hasDownloadedLength:downloadModel.URL];
    downloadModel.totalLength = totalLength;
    self.filesTotalLengthPlist[SRFileName(downloadModel.URL)] = @(totalLength);
    [self.filesTotalLengthPlist writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
    
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
            if (expectedSize != 0) {
                downloadModel.progress(receivedSize, expectedSize, 1.0 * receivedSize / expectedSize);
            }
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error && error.code == -999) { // cancel task will call this delegate method and the error's code is -999
        return;
    }
    SRDownloadModel *downloadModel = self.downloadModels[task.taskDescription];
    if (!downloadModel) {
        return;
    }
    [downloadModel closeOutputStream];
    [self.downloadModels removeObjectForKey:task.taskDescription];
    [self.downloadingModels removeObject:downloadModel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateFailed);
            }
            if (downloadModel.completion) {
                downloadModel.completion(NO, nil, error);
            }
        } else {
            if ([self isDownloadCompletedOfURL:downloadModel.URL]) {
                NSString *fullPath = [self fileFullPathOfURL:downloadModel.URL];
                NSString *destPath = downloadModel.destPath;
                if (destPath) {
                    [[NSFileManager defaultManager] moveItemAtPath:fullPath toPath:destPath error:nil];
                }
                if (downloadModel.state) {
                    downloadModel.state(SRDownloadStateCompleted);
                }
                if (downloadModel.completion) {
                    downloadModel.completion(YES, destPath ?: fullPath, nil);
                }
            } else {
                NSError *error = [NSError errorWithDomain:@"file download incomplete" code:0 userInfo:nil];
                if (downloadModel.state) {
                    downloadModel.state(SRDownloadStateFailed);
                }
                if (downloadModel.completion) {
                    downloadModel.completion(NO, nil, error);
                }
            }
        }
        [self resumeNextDowloadModel];
    });
}

#pragma mark - Assist Methods

/// check if the current downloading tasks is larger than the max concurrent downloads
- (BOOL)canResumeDownload {
    if (self.maxConcurrentCount == -1) {
        return YES;
    }
    if (self.downloadingModels.count < self.maxConcurrentCount) {
        return YES;
    }
    return NO;
}

- (NSInteger)totalLength:(NSURL *)URL {
    if (self.filesTotalLengthPlist.count == 0) {
        return 0;
    }
    if (!self.filesTotalLengthPlist[SRFileName(URL)]) {
        return 0;
    }
    return [self.filesTotalLengthPlist[SRFileName(URL)] integerValue];
}

- (NSInteger)hasDownloadedLength:(NSURL *)URL {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self fileFullPathOfURL:URL] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

- (void)resumeNextDowloadModel {
    if (self.maxConcurrentCount == -1) { // no limit so no waiting for download models
        return;
    }
    if (self.waitingModels.count == 0) {
        return;
    }
    SRDownloadModel *downloadModel;
    switch (self.waitingQueueMode) {
        case SRWaitingQueueModeFIFO:
            downloadModel = self.waitingModels.firstObject;
            break;
        case SRWaitingQueueModeFILO:
            downloadModel = self.waitingModels.lastObject;
            break;
    }
    [self.waitingModels removeObject:downloadModel];
    
    SRDownloadState downloadState;
    if ([self canResumeDownload]) {
        [self.downloadingModels addObject:downloadModel];
        [downloadModel.dataTask resume];
        downloadState = SRDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = SRDownloadStateWaiting;
    }
    if (downloadModel.state) {
        downloadModel.state(downloadState);
    }
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

- (void)setSaveFilesDirectory:(NSString *)saveFilesDirectory {
    _saveFilesDirectory = saveFilesDirectory;
    
    if (!saveFilesDirectory) {
        return;
    }
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:saveFilesDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:saveFilesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Downloads

- (void)suspendDownloadOfURL:(NSURL *)URL {
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (!downloadModel) {
        return;
    }
    if (downloadModel.state) {
        downloadModel.state(SRDownloadStateSuspended);
    }
    
    if ([self.waitingModels containsObject:downloadModel]) {
        [self.waitingModels removeObject:downloadModel];
    } else {
        [downloadModel.dataTask suspend];
        [self.downloadingModels removeObject:downloadModel];
    }
    
    [self resumeNextDowloadModel];
}

- (void)suspendAllDownloads {
    if (self.downloadModels.count == 0) {
        return;
    }
    if (self.waitingModels.count > 0) {
        for (NSInteger i = 0; i < self.waitingModels.count; i++) {
            SRDownloadModel *downloadModel = self.waitingModels[i];
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateSuspended);
            }
        }
        [self.waitingModels removeAllObjects];
    }
    if (self.downloadingModels.count > 0) {
        for (NSInteger i = 0; i < self.downloadingModels.count; i++) {
            SRDownloadModel *downloadModel = self.downloadingModels[i];
            [downloadModel.dataTask suspend];
            if (downloadModel.state) {
                downloadModel.state(SRDownloadStateSuspended);
            }
        }
        [self.downloadingModels removeAllObjects];
    }
}

- (void)resumeDownloadOfURL:(NSURL *)URL {
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (!downloadModel) {
        return;
    }
    SRDownloadState downloadState;
    if ([self canResumeDownload]) {
        [self.downloadingModels addObject:downloadModel];
        [downloadModel.dataTask resume];
        downloadState = SRDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = SRDownloadStateWaiting;
    }
    if (downloadModel.state) {
        downloadModel.state(downloadState);
    }
}

- (void)resumeAllDownloads {
    if (self.downloadModels.count == 0) {
        return;
    }
    NSArray *downloadModels = self.downloadModels.allValues;
    for (SRDownloadModel *downloadModel in downloadModels) {
        SRDownloadState downloadState;
        if ([self canResumeDownload]) {
            [self.downloadingModels addObject:downloadModel];
            [downloadModel.dataTask resume];
            downloadState = SRDownloadStateRunning;
        } else {
            [self.waitingModels addObject:downloadModel];
            downloadState = SRDownloadStateWaiting;
        }
        if (downloadModel.state) {
            downloadModel.state(downloadState);
        }
    }
}

- (void)cancelDownloadOfURL:(NSURL *)URL {
    SRDownloadModel *downloadModel = self.downloadModels[SRFileName(URL)];
    if (!downloadModel) {
        return;
    }
    [downloadModel closeOutputStream];
    [downloadModel.dataTask cancel];
    if (downloadModel.state) {
        downloadModel.state(SRDownloadStateCanceled);
    }
    
    if ([self.waitingModels containsObject:downloadModel]) {
        [self.waitingModels removeObject:downloadModel];
    } else {
        [self.downloadingModels removeObject:downloadModel];
    }
    [self.downloadModels removeObjectForKey:SRFileName(URL)];
    
    [self resumeNextDowloadModel];
}

- (void)cancelAllDownloads {
    if (self.downloadModels.count == 0) {
        return;
    }
    NSArray *downloadModels = self.downloadModels.allValues;
    for (SRDownloadModel *downloadModel in downloadModels) {
        [downloadModel closeOutputStream];
        [downloadModel.dataTask cancel];
        if (downloadModel.state) {
            downloadModel.state(SRDownloadStateCanceled);
        }
    }
    [self.waitingModels removeAllObjects];
    [self.downloadingModels removeAllObjects];
    [self.downloadModels removeAllObjects];
}

#pragma mark - Files

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
    
    [self.filesTotalLengthPlist removeObjectForKey:SRFileName(URL)];
    [self.filesTotalLengthPlist writeToFile:SRFilesTotalLengthPlistPath atomically:YES];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [SRDownloadDirectory stringByAppendingPathComponent:SRFileName(URL)];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)deleteAllFiles {
    [self cancelAllDownloads];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:SRDownloadDirectory error:nil];
    for (NSString *fileName in fileNames) {
        NSString *filePath = [SRDownloadDirectory stringByAppendingPathComponent:fileName];
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

@end
