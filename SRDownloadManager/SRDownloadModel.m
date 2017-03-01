//
//  SRDownloadModel.m
//
//  Created by 郭伟林 on 17/1/10.
//  Copyright © 2017年 SR. All rights reserved.
//

#import "SRDownloadModel.h"

@implementation SRDownloadModel

- (void)openOutputStream {
    
    if (_outputStream) {
        [_outputStream open];
    }
}

- (void)closeOutputStream {
    
    if (_outputStream) {
        [_outputStream close];
        _outputStream = nil;
    }
}

@end
