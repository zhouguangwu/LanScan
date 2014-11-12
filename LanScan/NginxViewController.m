//
//  NginxViewController.m
//  LanScan
//
//  Created by wayos-ios on 11/12/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import "NginxViewController.h"
#import "Nginx.h"


@interface NginxViewController ()<NginxDelegate>{
    UIImageView *imageView;
    Nginx *_nginx ;
}

@end

@implementation NginxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0, 430, 80, 30);
    [btn setTitle:@"nginx开始" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(_nginx:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.view addSubview:imageView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)_nginx:(UIButton *)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 2), ^{
         _nginx = [[Nginx alloc] init];
        _nginx.delegate = self;
        [_nginx start];
    });
    
}

- (void) nginx:(Nginx *)nginx didRecevidData:(NSData *)data{
//    [_nginx stop];//关闭这里有问题, 待研究
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageWithData:data];
        imageView.image = image;
    });
    
}
@end
