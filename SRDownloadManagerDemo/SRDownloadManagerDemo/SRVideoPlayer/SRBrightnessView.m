//
//  SRBrightnessView.m
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/4/6.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRBrightnessView.h"
#import "Masonry.h"

#define SRVideoPlayerImageName(fileName) [@"SRVideoPlayer.bundle" stringByAppendingPathComponent:fileName]

@interface SRBrightnessView ()

@property (nonatomic, strong) NSMutableArray *tips;

@end

@implementation SRBrightnessView

- (void)dealloc {
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
}

+ (instancetype)sharedBrightnessView {
    static SRBrightnessView *brightnessView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        brightnessView = [[SRBrightnessView alloc] init];
        [[UIApplication sharedApplication].keyWindow addSubview:brightnessView];
        [brightnessView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo([UIApplication sharedApplication].keyWindow);
            make.centerY.equalTo([UIApplication sharedApplication].keyWindow).offset(-5);
            make.width.mas_equalTo(155);
            make.height.mas_equalTo(155);
        }];
    });
    return brightnessView;
}

- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5, [UIScreen mainScreen].bounds.size.height * 0.5, 155, 155);
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        self.alpha = 0.0;
        
        {
            UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
            toolbar.alpha = 0.9;
            [self addSubview:toolbar]; // for blur effect
        }
        
        {
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.bounds.size.width, 30)];
            title.font = [UIFont boldSystemFontOfSize:16];
            title.textColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
            title.textAlignment = NSTextAlignmentCenter;
            title.text = @"亮度";
            [self addSubview:title];
        }
        
        {            
            UIImageView *brightnessIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
            brightnessIcon.center = CGPointMake(155 * 0.5, 155 * 0.5);
            brightnessIcon.image = [UIImage imageNamed:SRVideoPlayerImageName(@"brightness")];
            [self addSubview:brightnessIcon];
        }
        
        {
            UIView *tipsView = [[UIView alloc] initWithFrame:CGRectMake(13, 132, self.bounds.size.width - 26, 7)];
            tipsView.backgroundColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
            [self addSubview:tipsView];
            
            self.tips = [NSMutableArray arrayWithCapacity:16];
            CGFloat tipW = (tipsView.bounds.size.width - 17) / 16;
            CGFloat tipH = 5;
            CGFloat tipY = 1;
            for (int i = 0; i < 16; i++) {
                CGFloat tipX = i * (tipW + 1) + 1;
                UIImageView *image = [[UIImageView alloc] init];
                image.backgroundColor = [UIColor whiteColor];
                image.frame = CGRectMake(tipX, tipY, tipW, tipH);
                [tipsView addSubview:image];
                [self.tips addObject:image];
            }
            [self updateTips:[UIScreen mainScreen].brightness];
        }
        
        [[UIScreen mainScreen] addObserver:self forKeyPath:@"brightness" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    CGFloat newValue = [change[@"new"] floatValue];
    [self updateTips:newValue];
    
    if (self.alpha != 0) {
        return;
    }
    self.alpha = 1.0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeAway) withObject:nil afterDelay:2.0];
}

- (void)fadeAway {
    if (self.alpha != 1.0) {
        return;
    }
    [UIView animateWithDuration:0.8 animations:^{
        self.alpha = 0;
    }];
}

- (void)updateTips:(CGFloat)newValue {
    CGFloat stage = 1 / 15.0;
    NSInteger grade = newValue / stage;
    for (int i = 0; i < self.tips.count; i++) {
        UIImageView *tip = self.tips[i];
        if (i <= grade) {
            tip.hidden = NO;
        } else {
            tip.hidden = YES;
        }
    }
}

@end
