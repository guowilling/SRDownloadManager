//
//  SRVideoTopBar.h
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/1/6.
//  Copyright © 2017年 SR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SRVideoTopBarBarDelegate <NSObject>

- (void)videoTopBarDidClickCloseBtn;
- (void)videoTopBarDidClickDownloadBtn;

@end

@interface SRVideoTopBar : UIView

@property (nonatomic, weak) id<SRVideoTopBarBarDelegate> delegate;

+ (instancetype)videoTopBar;

- (void)setTitle:(NSString *)text;

@end
