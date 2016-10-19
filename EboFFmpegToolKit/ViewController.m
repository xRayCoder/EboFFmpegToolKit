//
//  ViewController.m
//  EboFFmpegToolKit
//
//  Created by xidi on 2016/10/19.
//  Copyright © 2016年 xidiAPP. All rights reserved.
//

#import "ViewController.h"
#import <libavcodec/avcodec.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    printf("%s", avcodec_configuration());
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
