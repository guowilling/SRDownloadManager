//
//  SRVideoBottomView.m
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/1/5.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRVideoBottomBar.h"
#import "Masonry.h"

static const CGFloat kItemWH = 60;

#define SRVideoPlayerImageName(fileName) [@"SRVideoPlayer.bundle" stringByAppendingPathComponent:fileName]

@interface SRVideoBottomBar ()

@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation SRVideoBottomBar

- (CAGradientLayer *)gradientLayer {
    [_gradientLayer removeFromSuperlayer];
    if (_gradientLayer) {
        _gradientLayer.frame = _gradientView.bounds;
    } else {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor];
        _gradientLayer.opacity = 1.0;
        _gradientLayer.frame = _gradientView.bounds;
    }
    return _gradientLayer;
}

- (UIButton *)playPauseBtn {
    if (!_playPauseBtn) {
        _playPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playPauseBtn.showsTouchWhenHighlighted = YES;
        [_playPauseBtn setImage:[UIImage imageNamed:SRVideoPlayerImageName(@"pause")] forState:UIControlStateNormal];
        [_playPauseBtn addTarget:self action:@selector(playPauseBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playPauseBtn;
}

- (UIButton *)changeScreenBtn {
    if (!_changeScreenBtn) {
        _changeScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeScreenBtn.showsTouchWhenHighlighted = YES;
        [_changeScreenBtn setImage:[UIImage imageNamed:SRVideoPlayerImageName(@"full_screen")] forState:UIControlStateNormal];
        [_changeScreenBtn addTarget:self action:@selector(changeScreenBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeScreenBtn;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:12.0];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel {
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc]init];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:12.0];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UISlider *)playingProgressSlider {
    if (!_playingProgressSlider) {
        _playingProgressSlider = [[UISlider alloc] init];
        _playingProgressSlider.minimumTrackTintColor = [UIColor whiteColor];
        _playingProgressSlider.maximumTrackTintColor = [UIColor colorWithWhite:0 alpha:0.5];
        [_playingProgressSlider setThumbImage:[UIImage imageNamed:SRVideoPlayerImageName(@"dot")] forState:UIControlStateNormal];
        [_playingProgressSlider addTarget:self action:@selector(sliderChanging:) forControlEvents:UIControlEventValueChanged];
        [_playingProgressSlider addTarget:self action:@selector(sliderDidEndChange:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapAction:)];
        [_playingProgressSlider addGestureRecognizer:tap];
    }
    return _playingProgressSlider;
}

- (UIProgressView *)cacheProgressView {
    if (!_cacheProgressView) {
        _cacheProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _cacheProgressView.progressTintColor = [UIColor colorWithWhite:1 alpha:0.75];
        _cacheProgressView.trackTintColor = [UIColor clearColor];
        _cacheProgressView.layer.cornerRadius = 0.5;
        _cacheProgressView.layer.masksToBounds = YES;
    }
    return _cacheProgressView;
}

+ (instancetype)videoBottomBar {
    return [[SRVideoBottomBar alloc] init];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _gradientView = [[UIView alloc] init];
        _gradientView.backgroundColor = [UIColor clearColor];
        [self addSubview:_gradientView];
        [_gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
        }];
        
        __weak typeof(self) weakSelf = self;
        
        [self addSubview:self.playPauseBtn];
        [self.playPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(kItemWH);
            make.height.mas_equalTo(kItemWH);
        }];
        
        [self addSubview:self.currentTimeLabel];
        [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.playPauseBtn.mas_right);
            make.top.mas_equalTo(0);
            make.width.mas_equalTo(55);
            make.height.mas_equalTo(kItemWH);
        }];
        
        [self addSubview:self.changeScreenBtn];
        [self.changeScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.width.mas_equalTo(kItemWH);
            make.height.mas_equalTo(kItemWH);
        }];
        
        [self addSubview:self.totalTimeLabel];
        [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.right.equalTo(weakSelf.changeScreenBtn.mas_left);
            make.width.mas_equalTo(55);
            make.height.mas_equalTo(kItemWH);
        }];
        
        [self addSubview:self.playingProgressSlider];
        [self.playingProgressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.currentTimeLabel.mas_right);
            make.top.mas_equalTo(0);
            make.right.equalTo(weakSelf.totalTimeLabel.mas_left);
            make.bottom.mas_equalTo(0);
        }];
        
        [self addSubview:self.cacheProgressView];
        [self.cacheProgressView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.currentTimeLabel.mas_right);
            make.right.equalTo(weakSelf.totalTimeLabel.mas_left);
            make.centerY.equalTo(weakSelf.playingProgressSlider.mas_centerY).offset(1);
            make.height.mas_equalTo(1);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.gradientView.layer addSublayer:self.gradientLayer];
}

- (void)playPauseBtnAction {
    if ([_delegate respondsToSelector:@selector(videoBottomBarDidClickPlayPauseBtn)]) {
        [_delegate videoBottomBarDidClickPlayPauseBtn];
    }
}

- (void)changeScreenBtnAction {
    if ([_delegate respondsToSelector:@selector(videoBottomBarDidClickChangeScreenBtn)]) {
        [_delegate videoBottomBarDidClickChangeScreenBtn];
    }
}

- (void)sliderChanging:(UISlider *)sender {
    if ([_delegate respondsToSelector:@selector(videoBottomBarChangingSlider:)]) {
        [_delegate videoBottomBarChangingSlider:sender];
    }
}

- (void)sliderDidEndChange:(UISlider *)sender {
    if ([_delegate respondsToSelector:@selector(videoBottomBarDidEndChangeSlider:)]) {
        [_delegate videoBottomBarDidEndChangeSlider:sender];
    }
}

- (void)sliderTapAction:(UITapGestureRecognizer *)tap {
    if ([_delegate respondsToSelector:@selector(videoBottomBarDidTapSlider:withTap:)]) {
        [_delegate videoBottomBarDidTapSlider:self.playingProgressSlider withTap:tap];
    }
}

@end
