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
#import "NginxViewController.h"
#import "AppDelegate.h"
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
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        struct in_addr ipAddr,maskAddr;//ntoa出来是大端的
//        inet_aton([NetUtils netMask].UTF8String, &maskAddr);
//        inet_aton([NetUtils localIp2].UTF8String, &ipAddr);
//        unsigned int hostCount = 0xffffffff / maskAddr.s_addr - 2;
//        for (unsigned int i = 1; i <= hostCount; i++) {
//            unsigned int netIp = ipAddr.s_addr & maskAddr.s_addr;
//            struct in_addr targetIp = {netIp + htonl(i)};
//            NSString *ipStr = [NSString stringWithFormat:@"%s",inet_ntoa(targetIp)];
//            BOOL isOk = [NetUtils ping:ipStr];
//            NSLog(@"ping %@",ipStr);
//            if (isOk) {
//                NSLog(@"%@找到一个",ipStr);
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self _reload];
//            });
//        }
//    });
    
    //https
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://114.215.128.233/"]];
    //    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com/hhfa008/HTTPSURLProtocol/blob/master/HTTPSURLProtocol.m"]];
    [NSURLConnection connectionWithRequest:request delegate:self];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0, 430, 80, 30);
    [btn setTitle:@"nginx开始" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(_nginx:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *udpBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 430, 50, 20)];
    udpBtn.backgroundColor = [UIColor yellowColor];
    [udpBtn setTitle:@"udp" forState:UIControlStateNormal];
    [udpBtn addTarget:self action:@selector(_udp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:udpBtn];
}

- (void) _udp{
    NSData *data = [NetUtils udpTo:@"127.0.0.1" port:8888 data:[@"abc" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"udpresult=>%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void) _reload{
    NSArray *status = @[@"无网",@"wifi",@"gprs"];
    _infoView.text = [NSString stringWithFormat:@"当前ip,%@,掩码,%@,网关:%@,广播地址%@,ssid:%@,bssid:%@,mac:%@,当前网络状态 %@,\n当前的内网设备有%@",
                      [NetUtils localIp2],[NetUtils netMask],[NetUtils gateway2],[NetUtils broadcastIp],[NetUtils ssid],[NetUtils bssid],[NetUtils mac],status[[NetUtils currentNetWorkStatus]],[NetUtils arpTable]
                      ];
}

- (void)_nginx:(UIButton *)sender{
    NginxViewController *ngVC = [[NginxViewController alloc] init];
//    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:ngVC];
    [(AppDelegate *)[UIApplication sharedApplication].delegate window].rootViewController = ngVC;
}


- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    NSLog(@"%@",protectionSpace.authenticationMethod);
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    NSLog(@"%@,%@,%d",credential,credential.password,credential.hasPassword);
    [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];//自己的必须这样
//    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];//github可以不用证书, 但是自己的必须要证书
    NSLog(@"%@",challenge);
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",str);
}
@end
