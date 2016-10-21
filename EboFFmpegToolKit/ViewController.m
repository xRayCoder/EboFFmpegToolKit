//
//  ViewController.m
//  EboFFmpegToolKit
//
//  Created by xidi on 2016/10/19.
//  Copyright © 2016年 xidiAPP. All rights reserved.
//

#import "ViewController.h"
#import <libavcodec/avcodec.h>
#import "EboDecoder.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) EboDecoder * decoder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    printf("%s", avcodec_configuration());
    
    _decoder = [[EboDecoder alloc] initWithVideo:@"http://pl.youku.com/playlist/m3u8?vid=XMTU4MTI3ODkxMg&type=flv&ts=1471244697&keyframe=0&ep=ciaTG0uJUsgJ4iLXiD8bM3rhc3EPXJZ0gkzC%2FKYxA8ZAE%2BrQmTvRww%3D%3D&sid=047124469718012df3760&token=0504&ctype=12&ev=1&oip=3031274439"];
    [_decoder seekTime:0.0f];
    
    [NSTimer scheduledTimerWithTimeInterval: 1 / _decoder.fps
                                     target:self
                                   selector:@selector(displayNextFrame:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) displayNextFrame:(NSTimer *)timer {

    // 到最后一帧时，停止计时器
    if (![_decoder goToNextFrame]) {
        [timer invalidate];
        return;
    }
    
    [_decoder goToNextFrame];
    _imageView.image = [_decoder currentImageFromAVPicture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
