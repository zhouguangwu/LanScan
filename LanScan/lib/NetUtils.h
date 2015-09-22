//
//  NetUtils.h
//  Utils
//
//  Created by kenny on 7/4/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum :int{
	NetworkStatusNotReachable = 0,
	NetworkStatusReachableViaWiFi,
	NetworkStatusReachableViaWWAN
} CurrentNetworkStatus;
@interface NetUtils : NSObject
+ (NSString *) hostToIp:(NSString *) host;
//支持ipv6
+ (NSString *) hostToIp2:(NSString *)host;
+ (NSString *) ip2Net:(NSString *) ip;
+ (NSString *) ip2HostIp:(NSString *) ip;
+ (NSString *) localIp;
+ (NSString *) localIp2;
+ (NSString *) broadcastIp;
+ (NSString *) netMask;
+ (NSString *) mac;
+ (NSString *) ssid;
+ (NSString *) bssid;
+ (CurrentNetworkStatus) currentNetWorkStatus;
+ (NSString *) gateway;
+ (NSString *) gateway2;
+ (NSString *) ip2Host:(NSString *)ip;
+ (int) getServPortByName:(NSString *)name;
+ (NSArray *) arpTable;
+ (BOOL) ping:(NSString *) ip;
@end
