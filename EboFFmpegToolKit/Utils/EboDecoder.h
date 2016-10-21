//
//  EboDecoder.h
//  EboFFmpegToolKit
//
//  Created by xidi on 2016/10/20.
//  Copyright © 2016年 xidiAPP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EboDecoder : NSObject

// 帧率
@property (nonatomic) double fps;

- (instancetype)initWithVideo:(NSString *)videoPath;

// 跳到指定的时间（秒）
- (void) seekTime:(double)seconds;

// 跳到下一帧
- (BOOL)goToNextFrame;

// 从AVPicture获取UIImage
- (UIImage *)currentImageFromAVPicture;

@end
