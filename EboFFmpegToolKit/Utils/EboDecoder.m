//
//  EboDecoder.m
//  EboFFmpegToolKit
//
//  Created by xidi on 2016/10/20.
//  Copyright © 2016年 xidiAPP. All rights reserved.
//

#import "EboDecoder.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>

@interface EboDecoder ()

@property (nonatomic) AVFormatContext * avFormatContext;
@property (nonatomic) AVCodecContext * avCodecContext;
@property (nonatomic) AVFrame * avFrame;
@property (nonatomic) AVStream * stream;
@property (nonatomic) AVPacket packet;
@property (nonatomic) AVPicture avPicture;
@property (nonatomic) int videoStreamNum;

@property (nonatomic) BOOL releasingResources;
/* 输出图像大小。默认设置为源大小。 */
@property (nonatomic,assign) int outputWidth, outputHeight;

@end

@implementation EboDecoder

- (instancetype)initWithVideo:(NSString *)videoPath {
    
    self = [super init];
    if (self) {
        
        [self setupDecoderWith:[videoPath UTF8String]];
    }
    return self;
}

- (BOOL)setupDecoderWith:(const char *)videoPath {

    BOOL result = YES;
    
    AVCodec * pCodec;
    
    // 注册所有解码器
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    
    // 打开视频文件
    if (avformat_open_input(&_avFormatContext, videoPath, NULL, NULL) != 0) {
        NSLog(@"打开文件失败");
        return NO;
    }
    
    // 检查数据流
    if (avformat_find_stream_info(_avFormatContext, NULL) < 0) {
        NSLog(@"检查数据流失败");
        return NO;
    }
    
    // 根据数据流，找到第一个视频流
    if ((_videoStreamNum = av_find_best_stream(_avFormatContext, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0))) {
        NSLog(@"没有找到第一个视频流");
        return NO;
    }
    
    // 获取视频流的编解码上下文
    _stream = _avFormatContext -> streams[_videoStreamNum];
    _avCodecContext = _stream -> codec;
    
    
    // 打印视频流的详细信息
    av_dump_format(_avFormatContext, _videoStreamNum, videoPath, 0);
    
    if (_stream -> avg_frame_rate.den && _stream -> avg_frame_rate.num) {
        _fps = av_q2d(_stream -> avg_frame_rate);
    }
    else {
        _fps = 30.0f;
    }
    
    // 查找解码器
    pCodec = avcodec_find_decoder(_avCodecContext -> codec_id);
    if (pCodec == NULL) {
        NSLog(@"没有找到解码器");
        return NO;
    }
    
    // 打开解码器
    if (avcodec_open2(_avCodecContext, pCodec, NULL) < 0) {
        NSLog(@"打开解码器失败");
        return NO;
    }
    
    // 分配视频帧
    _avFrame = av_frame_alloc();
    _outputWidth = _avCodecContext -> width;
    _outputHeight = _avCodecContext -> height;
    
    return result;
}

// 跳到指定的时间（秒）
- (void) seekTime:(double)seconds {

    AVRational timeBase = _stream -> time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
    
    avformat_seek_file(_avFormatContext, _videoStreamNum, 0, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
    avcodec_flush_buffers(_avCodecContext);
}

// 跳到下一帧
- (BOOL)goToNextFrame {

    int reachedLastFrame = 0;
    
    while (!reachedLastFrame && av_read_frame(_avFormatContext, &_packet) >= 0) {
        if (_packet.stream_index == _videoStreamNum) {
            avcodec_decode_video2(_avCodecContext, _avFrame, &reachedLastFrame, &_packet);
        }
    }
    
    if (reachedLastFrame == 0 && !_releasingResources) {
        [self releaseResource];
    }
    
    return reachedLastFrame != 0;
}

// 从AVPicture获取UIImage
- (UIImage *)currentImageFromAVPicture{

    avpicture_free(&_avPicture);
    avpicture_alloc(&_avPicture,
                    AV_PIX_FMT_BGR24,
                    _outputWidth,
                    _outputHeight);
    struct SwsContext * imageConvertContext = sws_getContext(_avFrame -> width,
                                                             _avFrame -> height,
                                                             AV_PIX_FMT_YUV420P,
                                                             _outputWidth,
                                                             _outputHeight,
                                                             AV_PIX_FMT_BGR24,
                                                             SWS_FAST_BILINEAR,
                                                             NULL,
                                                             NULL,
                                                             NULL);
    if (!imageConvertContext) {
        return nil;
    }
    
    sws_scale(imageConvertContext, _avFrame ->data, _avFrame ->linesize, 0, _avFrame ->height, _avPicture.data, _avPicture.linesize);
    sws_freeContext(imageConvertContext);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreate(kCFAllocatorDefault,
                                  _avPicture.data[0],
                                  _avPicture.linesize[0] * _outputHeight);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(_outputWidth,
                                       _outputHeight,
                                       8,
                                       24,
                                       _avPicture.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    
    UIImage * image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

- (void) releaseResource {

    _releasingResources = YES;
    
    // 释放RGB
//    avpicture_free()
    
    // 释放frame
    av_packet_unref(&_packet);
    
    // 释放YUV frame
    av_free(_avFrame);
    
    // 关闭解码器
    if (_avCodecContext) {
        avcodec_close(_avCodecContext);
    }
    
    // 关闭文件
    if (_avFormatContext) {
        avformat_network_deinit();
    }
}

@end
