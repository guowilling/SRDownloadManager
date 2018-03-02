//
//  SRVideoOperationTip.m
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/1/5.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRVideoProgressTip.h"
#import "Masonry.h"

#define SRVideoPlayerImageName(fileName) [@"SRVideoPlayer.bundle" stringByAppendingPathComponent:fileName]

@interface SRVideoProgressTip ()

@property (nonatomic, strong) UIImageView *tipImageView;

@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation SRVideoProgressTip

- (UIImageView *)tipImageView {
    if (!_tipImageView) {
        _tipImageView = [[UIImageView alloc] init];
        _tipImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_tipImageView setImage:[UIImage imageNamed:SRVideoPlayerImageName(@"progress_left")]];
    }
    return _tipImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.font = [UIFont systemFontOfSize:15];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        __weak typeof(self) weakSelf = self;
        
        [self addSubview:self.tipImageView];
        [self.tipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(20);
            make.width.mas_equalTo(60);
            make.height.mas_equalTo(30);
            make.centerX.equalTo(weakSelf);
        }];
        
        [self addSubview:self.tipLabel];
        [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_tipImageView.mas_bottom);
            make.width.mas_equalTo(150);
            make.height.mas_equalTo(30);
            make.centerX.equalTo(weakSelf);
        }];
    }
    return self;
}

- (void)setTipImageViewImage:(UIImage *)image {
    self.tipImageView.image = image;
}

- (void)setTipLabelText:(NSString *)text {
    self.tipLabel.text = text;
}

@end
