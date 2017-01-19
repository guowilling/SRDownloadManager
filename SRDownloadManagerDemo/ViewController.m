//
//  ViewController.m
//  SRDownloadManagerDemo
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "ViewController.h"
#import "SRDownloadManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *progressLabel1;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel2;

@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel1;
@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel2;

@property (weak, nonatomic) IBOutlet UILabel *currentSizeLabel1;
@property (weak, nonatomic) IBOutlet UILabel *currentSizeLabel2;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;

@property (weak, nonatomic) IBOutlet UIButton *downloadButton1;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton2;

@end

NSString * const downloadURLString1 = @"http://baobab.wdjcdn.com/1442142801331138639111.mp4";
NSString * const downloadURLString2 = @"http://baobab.wdjcdn.com/14564977406580.mp4";

#define kDownloadURL1 [NSURL URLWithString:downloadURLString1]
#define kDownloadURL2 [NSURL URLWithString:downloadURLString2]

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    CGFloat progress1 = [[SRDownloadManager sharedManager] progress:kDownloadURL1];
    CGFloat progress2 = [[SRDownloadManager sharedManager] progress:kDownloadURL2];
    NSLog(@"progressOfResource downloadURLString1: %f", progress1);
    NSLog(@"progressOfResource downloadURLString2: %f", progress2);
    self.progressView1.progress = progress1;
    self.progressLabel1.text = [NSString stringWithFormat:@"%.f%%", progress1 * 100];
    [self.downloadButton1 setTitle:[self titleWithDownloadState:[self stateWithProgress:progress1]]
                          forState:UIControlStateNormal];
    self.progressView2.progress = progress2;
    self.progressLabel2.text = [NSString stringWithFormat:@"%.f%%", progress2 * 100];
    [self.downloadButton2 setTitle:[self titleWithDownloadState:[self stateWithProgress:progress2]]
                          forState:UIControlStateNormal];
    
    if ([[SRDownloadManager sharedManager] isCompleted:kDownloadURL1]) {
        NSLog(@"%@", [[SRDownloadManager sharedManager] fileFullPath:kDownloadURL1]);
    }
    if ([[SRDownloadManager sharedManager] isCompleted:kDownloadURL2]) {
        NSLog(@"%@", [[SRDownloadManager sharedManager] fileFullPath:kDownloadURL2]);
    }
}

- (NSString *)titleWithDownloadState:(SRDownloadState)state {
    
    switch (state) {
        case SRDownloadStateRunning:
            return @"Pause";
        case SRDownloadStateSuspended:
            return @"Resume";
        case SRDownloadStateCompleted:
            return @"Finish";
        case SRDownloadStateFailed:
            return @"Start";
    }
}

- (SRDownloadState)stateWithProgress:(CGFloat)progress {
    
    SRDownloadState state;
    if (progress == 1.0) {
        state = SRDownloadStateCompleted;
    } else if (progress > 0) {
        state = SRDownloadStateSuspended;
    } else {
        state = SRDownloadStateFailed;
    }
    return state;
}

#pragma mark - Actions

- (IBAction)clearAllFiles:(id)sender {
    
    [[SRDownloadManager sharedManager] deleteAllFiles];
    
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
    self.progressLabel1.text = @"0%";
    self.progressLabel2.text = @"0%";
    self.progressView1.progress = 0.0;
    self.progressView2.progress = 0.0;
    self.currentSizeLabel1.text = @"0";
    self.currentSizeLabel2.text = @"0";
    self.totalSizeLabel1.text = @"0";
    self.totalSizeLabel2.text = @"0";
}

- (IBAction)downloadFile1:(UIButton *)sender {
    
    [self download:kDownloadURL1
    totalSizeLabel:self.totalSizeLabel1 currentSizeLabel:self.currentSizeLabel1
     progressLabel:self.progressLabel1 progressView:self.progressView1
            button:sender];
}

- (IBAction)downloadFile2:(UIButton *)sender {
    
    [self download:kDownloadURL2
    totalSizeLabel:self.totalSizeLabel2 currentSizeLabel:self.currentSizeLabel2
     progressLabel:self.progressLabel2 progressView:self.progressView2
            button:sender];
}

- (void)download:(NSURL *)URL totalSizeLabel:(UILabel *)totalSizeLabel currentSizeLabel:(UILabel *)currentSizeLabel
   progressLabel:(UILabel *)progressLabel progressView:(UIProgressView *)progressView
          button:(UIButton *)button
{
    [[SRDownloadManager sharedManager] download:URL
                                          state:^(SRDownloadState state) {
                                              [button setTitle:[self titleWithDownloadState:state] forState:UIControlStateNormal];
                                          }
                                       progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
                                           totalSizeLabel.text = [NSString stringWithFormat:@"%zdMB", expectedSize / 1024 / 1024];
                                           currentSizeLabel.text = [NSString stringWithFormat:@"%zdMB", receivedSize / 1024 / 1024];
                                           progressLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100];
                                           progressView.progress = progress;
                                       }
                                     completion:^(BOOL isSuccess, NSString *filePath, NSError *error) {
                                         if (isSuccess) {
                                             NSLog(@"%@", filePath);
                                         } else {
                                             NSLog(@"%@", error);
                                         }
                                     }];
}

- (IBAction)deleteFile1:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] deleteFile:kDownloadURL1];
    
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
    self.progressLabel1.text    = @"0%";
    self.progressView1.progress = 0.0;
    self.currentSizeLabel1.text = @"0";
    self.totalSizeLabel1.text   = @"0";
}

- (IBAction)deleteFile2:(UIButton *)sender {
    
    [[SRDownloadManager sharedManager] deleteFile:kDownloadURL2];
    
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
    self.progressLabel2.text    = @"0%";
    self.progressView2.progress = 0.0;
    self.currentSizeLabel2.text = @"0";
    self.totalSizeLabel2.text   = @"0";
}

@end
