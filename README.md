# SRDownloadManager

File download manager based on NSURLSession. Provide multitasking download at the same time and breakpoint download even exit the App function. Provide download status callback, progress callback and completion callback.

## Features

* [x] Support to customize the directory where the downloaded files are saved.
* [x] Support to set maximum concurrent downloads and waiting for download queue mode.
* [x] Support to delete the specified file by URL and clear all files that have been downloaded.

## Screenshots

![image](./screenshots1.png) ![image](./screenshots2.png)

## Installation

**CocoaPods**
> Add **pod 'SRDownloadManager'** to the Podfile, then run **pod install** in the terminal.

**Manual**
> Drag the **SRDownloadManager** folder to the project.

## Usage

````objc
/**
 Starts a download action with URL and download state, progress, completion callback block.

 @param URL        The URL of the file which to be downloaded.
 @param state      A block object to be executed when the download state changed.
 @param progress   A block object to be executed when the download progress changed.
 @param completion A block object to be executed when the download completion.
 */
- (void)downloadFileOfURL:(NSURL *)URL
                    state:(void (^)(SRDownloadState state))state
                 progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
               completion:(void (^)(BOOL success, NSString *filePath, NSError *error))completion;
````

````objc
[[SRDownloadManager sharedManager] downloadFileOfURL:URL state:^(SRDownloadState state) {
    // Called when the download state changed.
} progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
    // Called when the download progress changed.
} completion:^(BOOL success, NSString *filePath, NSError *error) {
    // Called when the download completion.
}];
````

## Custom

````objc
/**
 The directory where the downloaded files are saved, default is .../Library/Caches/SRDownloadManager if not setted.
 */
@property (nonatomic, copy) NSString *downloadedFilesDirectory;

/**
 The count of max concurrent downloads, default is -1 which means no limit.
 */
@property (nonatomic, assign) NSInteger maxConcurrentDownloadCount;

/**
 The mode of waiting for download queue, default is FIFO.
 */
@property (nonatomic, assign) SRWaitingDownloadQueueMode waitingDownloadQueueMode;
````

## More

For more contens please see the demo.  
Submit an issue or email me if you have any questions.