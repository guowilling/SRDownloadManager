//
//  SRVideoLayerView.m
//  SRVideoPlayer
//
//  Created by https://github.com/guowilling on 17/1/5.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRPlayerLayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation SRPlayerLayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end
