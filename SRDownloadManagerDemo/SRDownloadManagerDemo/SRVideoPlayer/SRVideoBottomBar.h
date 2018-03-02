//
//  SRVideoBottomView.h
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/1/5.
//  Copyright © 2017年 SR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SRVideoBottomBarDelegate <NSObject>

- (void)videoBottomBarDidClickPlayPauseBtn;
- (void)videoBottomBarDidClickChangeScreenBtn;
- (void)videoBottomBarDidTapSlider:(UISlider *)slider withTap:(UITapGestureRecognizer *)tap;
- (void)videoBottomBarChangingSlider:(UISlider *)slider;
- (void)videoBottomBarDidEndChangeSlider:(UISlider *)slider;

@end

@interface SRVideoBottomBar : UIView

@property (nonatomic, weak) id<SRVideoBottomBarDelegate> delegate;

@property (nonatomic, strong) UIButton *playPauseBtn;
@property (nonatomic, strong) UIButton *changeScreenBtn;

@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *totalTimeLabel;

@property (nonatomic, strong) UISlider *playingProgressSlider;

@property (nonatomic, strong) UIProgressView *cacheProgressView;

+ (instancetype)videoBottomBar;

@end
