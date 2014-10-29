//
//  ViewController.m
//  LanScan
//
//  Created by wayos-ios on 10/13/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import "ViewController.h"
#import "NetUtils.h"
#import <netinet/in.h>
#import <arpa/inet.h>
@interface ViewController (){
    UITextView *_infoView;
}

@end

@implementation ViewController

- (void)loadView{
    [super loadView];
    _infoView = [[UITextView alloc] initWithFrame:CGRectMake(0, 30, 320, 400)];
    _infoView.editable = NO;
    [self.view addSubview:_infoView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _reload];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        struct in_addr ipAddr,maskAddr;//ntoa出来是大端的
        inet_aton([NetUtils netMask].UTF8String, &maskAddr);
        inet_aton([NetUtils localIp2].UTF8String, &ipAddr);
        unsigned int hostCount = 0xffffffff / maskAddr.s_addr - 2;
        for (unsigned int i = 1; i <= hostCount; i++) {
            unsigned int netIp = ipAddr.s_addr & maskAddr.s_addr;
            struct in_addr targetIp = {netIp + htonl(i)};
            NSString *ipStr = [NSString stringWithFormat:@"%s",inet_ntoa(targetIp)];
            BOOL isOk = [NetUtils ping:ipStr];
            NSLog(@"ping %@",ipStr);
            if (isOk) {
                NSLog(@"%@找到一个",ipStr);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _reload];
            });
        }
    });
}

- (void) _reload{
    NSArray *status = @[@"无网",@"wifi",@"gprs"];
    _infoView.text = [NSString stringWithFormat:@"当前ip,%@,掩码,%@,网关:%@,广播地址%@,ssid:%@,bssid:%@,mac:%@,当前网络状态 %@,\n当前的内网设备有%@",
                      [NetUtils localIp2],[NetUtils netMask],[NetUtils gateway2],[NetUtils broadcastIp],[NetUtils ssid],[NetUtils bssid],[NetUtils mac],status[[NetUtils currentNetWorkStatus]],[NetUtils arpTable]
                      ];
}

@end
