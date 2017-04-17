//
//  ViewController.m
//  SRDownloadManagerDemo
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "ViewController.h"
#import "SRDownloadManager.h"

NSString * const downloadURLString1 = @"http://baobab.wdjcdn.com/14564977406580.mp4";
NSString * const downloadURLString2 = @"http://baobab.wdjcdn.com/1442142801331138639111.mp4";
NSString * const downloadURLString3 = @"http://baobab.wdjcdn.com/1455888619273255747085_x264.mp4";

#define kDownloadURL1 [NSURL URLWithString:downloadURLString1]
#define kDownloadURL2 [NSURL URLWithString:downloadURLString2]
#define kDownloadURL3 [NSURL URLWithString:downloadURLString3]

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *downloadButton1;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton2;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton3;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView3;

@property (weak, nonatomic) IBOutlet UILabel *progressLabel1;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel2;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel3;

@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel1;
@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel2;
@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel3;

@property (weak, nonatomic) IBOutlet UILabel *currentSizeLabel1;
@property (weak, nonatomic) IBOutlet UILabel *currentSizeLabel2;
@property (weak, nonatomic) IBOutlet UILabel *currentSizeLabel3;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    if ([[SRDownloadManager sharedManager] isDownloadCompletedOfURL:kDownloadURL1]) {
        NSLog(@"%@", [[SRDownloadManager sharedManager] fileFullPathOfURL:kDownloadURL1]);
    }
    if ([[SRDownloadManager sharedManager] isDownloadCompletedOfURL:kDownloadURL2]) {
        NSLog(@"%@", [[SRDownloadManager sharedManager] fileFullPathOfURL:kDownloadURL2]);
    }
    if ([[SRDownloadManager sharedManager] isDownloadCompletedOfURL:kDownloadURL3]) {
        NSLog(@"%@", [[SRDownloadManager sharedManager] fileFullPathOfURL:kDownloadURL3]);
    }
    
    // Uncomment the following line to customize the directory where the downloaded files are saved.
//    [SRDownloadManager sharedManager].downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] \
//                                                           stringByAppendingPathComponent:@"CustomDownloadDirectory"];
    
    // Uncomment the following line to customize the Maximum concurrent downloads
    [SRDownloadManager sharedManager].maxConcurrentDownloadCount = 1;
    
    // Uncomment the following line to customize the queue for waiting downloads.
    [SRDownloadManager sharedManager].waitingQueueMode = SRWaitingQueueFILO;
    
    CGFloat progress1 = [[SRDownloadManager sharedManager] fileHasDownloadedProgressOfURL:kDownloadURL1];
    CGFloat progress2 = [[SRDownloadManager sharedManager] fileHasDownloadedProgressOfURL:kDownloadURL2];
    CGFloat progress3 = [[SRDownloadManager sharedManager] fileHasDownloadedProgressOfURL:kDownloadURL3];
    NSLog(@"progress of downloadURL1: %.2f", progress1);
    NSLog(@"progress of downloadURL2: %.2f", progress2);
    NSLog(@"progress of downloadURL3: %.2f", progress3);
    
    self.progressView1.progress = progress1;
    self.progressLabel1.text = [NSString stringWithFormat:@"%.f%%", progress1 * 100];
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
    
    self.progressView2.progress = progress2;
    self.progressLabel2.text = [NSString stringWithFormat:@"%.f%%", progress2 * 100];
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
    
    self.progressView3.progress = progress3;
    self.progressLabel3.text = [NSString stringWithFormat:@"%.f%%", progress3 * 100];
    [self.downloadButton3 setTitle:@"Start" forState:UIControlStateNormal];
}

#pragma mark - Actions

- (IBAction)deleteAllFiles:(UIBarButtonItem *)sender {
    
    [[SRDownloadManager sharedManager] deleteAllFiles];
    
    self.progressView1.progress = 0.0;
    self.progressView2.progress = 0.0;
    self.progressView3.progress = 0.0;
    
    self.currentSizeLabel1.text = @"0";
    self.currentSizeLabel2.text = @"0";
    self.currentSizeLabel3.text = @"0";
    
    self.totalSizeLabel1.text = @"0";
    self.totalSizeLabel2.text = @"0";
    self.totalSizeLabel3.text = @"0";
    
    self.progressLabel1.text = @"0%";
    self.progressLabel2.text = @"0%";
    self.progressLabel3.text = @"0%";
    
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton3 setTitle:@"Start" forState:UIControlStateNormal];
}

- (IBAction)downloadFile1:(UIButton *)sender {
    
    [self download:kDownloadURL1
    totalSizeLabel:self.totalSizeLabel1
  currentSizeLabel:self.currentSizeLabel1
     progressLabel:self.progressLabel1
      progressView:self.progressView1
            button:sender];
}

- (IBAction)downloadFile2:(UIButton *)sender {
    
    [self download:kDownloadURL2
    totalSizeLabel:self.totalSizeLabel2
  currentSizeLabel:self.currentSizeLabel2
     progressLabel:self.progressLabel2
      progressView:self.progressView2
            button:sender];
}

- (IBAction)downloadFile3:(UIButton *)sender {
    
    [self download:kDownloadURL3
    totalSizeLabel:self.totalSizeLabel3
  currentSizeLabel:self.currentSizeLabel3
     progressLabel:self.progressLabel3
      progressView:self.progressView3
            button:sender];
}

- (void)download:(NSURL *)URL totalSizeLabel:(UILabel *)totalSizeLabel currentSizeLabel:(UILabel *)currentSizeLabel progressLabel:(UILabel *)progressLabel progressView:(UIProgressView *)progressView button:(UIButton *)button {
    
    if ([button.currentTitle isEqualToString:@"Start"]) {
        [[SRDownloadManager sharedManager] downloadFileOfURL:URL
                                                       state:^(SRDownloadState state) {
                                                           [button setTitle:[self titleWithDownloadState:state] forState:UIControlStateNormal];
                                                       } progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
                                                           currentSizeLabel.text = [NSString stringWithFormat:@"%zdMB", receivedSize / 1024 / 1024];
                                                           totalSizeLabel.text = [NSString stringWithFormat:@"%zdMB", expectedSize / 1024 / 1024];
                                                           progressLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100];
                                                           progressView.progress = progress;
                                                       } completion:^(BOOL success, NSString *filePath, NSError *error) {
                                                           if (success) {
                                                               NSLog(@"FilePath: %@", filePath);
                                                           } else {
                                                               NSLog(@"Error: %@", error);
                                                           }
                                                       }];
    } else if ([button.currentTitle isEqualToString:@"Waiting"]) {
        [[SRDownloadManager sharedManager] cancelDownloadOfURL:URL];
    } else if ([button.currentTitle isEqualToString:@"Pause"]) {
        [[SRDownloadManager sharedManager] suspendDownloadOfURL:URL];
    } else if ([button.currentTitle isEqualToString:@"Resume"]) {
        [[SRDownloadManager sharedManager] resumeDownloadOfURL:URL];
    } else if ([button.currentTitle isEqualToString:@"Finish"]) {
        NSLog(@"File has been downloaded! File path: %@", [[SRDownloadManager sharedManager] fileFullPathOfURL:URL]);
    }
}

- (NSString *)titleWithDownloadState:(SRDownloadState)state {
    
    switch (state) {
        case SRDownloadStateWaiting:
            return @"Waiting";
        case SRDownloadStateRunning:
            return @"Pause";
        case SRDownloadStateSuspended:
            return @"Resume";
        case SRDownloadStateCanceled:
            return @"Start";
        case SRDownloadStateCompleted:
            return @"Finish";
        case SRDownloadStateFailed:
            return @"Start";
    }
}

- (IBAction)deleteFile1:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] deleteFileOfURL:kDownloadURL1];
    
    self.progressView1.progress = 0.0;
    self.currentSizeLabel1.text = @"0";
    self.totalSizeLabel1.text = @"0";
    self.progressLabel1.text = @"0%";
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
}

- (IBAction)deleteFile2:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] deleteFileOfURL:kDownloadURL2];
    
    self.progressView2.progress = 0.0;
    self.currentSizeLabel2.text = @"0";
    self.totalSizeLabel2.text = @"0";
    self.progressLabel2.text = @"0%";
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
}

- (IBAction)deleteFile3:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] deleteFileOfURL:kDownloadURL3];
    
    self.progressView3.progress = 0.0;
    self.currentSizeLabel3.text = @"0";
    self.totalSizeLabel3.text = @"0";
    self.progressLabel3.text = @"0%";
    [self.downloadButton3 setTitle:@"Start" forState:UIControlStateNormal];
}

- (IBAction)suspendAllDownloads:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] suspendAllDownloads];
}

- (IBAction)resumeAllDownloads:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] resumeAllDownloads];
}

- (IBAction)cancelAllDownloads:(UIBarButtonItem *)sender {
    
    [[SRDownloadManager sharedManager] cancelAllDownloads];
}

@end
