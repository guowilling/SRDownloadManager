# SRDownloadManager

## Features

* Provides download status callback, download progress callback, download complete callback.
* Support multi-task at the same time to download.
* Support breakpoint to continue to download, even exit the App.
* Support to delete the specified file or all files that have been downloaded.
* More please see the demo...

## Show Pictures

## APIs

````objc
+ (instancetype)sharedManager;

- (void)download:(NSURL *)URL
           state:(void(^)(SRDownloadState state))state
        progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progress
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *error))completion;

- (BOOL)isCompleted:(NSURL *)URL;

- (NSString *)fileFullPath:(NSURL *)URL;

- (CGFloat)progress:(NSURL *)URL;

- (void)deleteFile:(NSURL *)URL;

- (void)deleteAllFiles;
````

**If you have any question, please issue or contact me.**   
**If this repo helps you, please give it a star.**  
**Have Fun.**