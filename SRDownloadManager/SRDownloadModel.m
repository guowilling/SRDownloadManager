//
//  SRDownloadModel.m
//  SRDownloadManager
//
//  Created by https://github.com/guowilling on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadModel.h"

@implementation SRDownloadModel

- (void)openOutputStream {
    
    if (!_outputStream) {
        return;
    }
    [_outputStream open];
}

- (void)closeOutputStream {
    
    if (!_outputStream) {
        return;
    }
    if (_outputStream.streamStatus > NSStreamStatusNotOpen && _outputStream.streamStatus < NSStreamStatusClosed) {
        [_outputStream close];
    }
    _outputStream = nil;
}

@end
