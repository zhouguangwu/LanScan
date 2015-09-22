//
//  NetUtils.m
//  Utils
//
//  Created by kenny on 7/4/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import "NetUtils.h"
#import "netdb.h"
#import "arpa/inet.h"
#import "ifaddrs.h"
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#if TARGET_IPHONE_SIMULATOR
#import <net/route.h>
#else
#import "route.h"
#endif
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <netinet/in.h>
#import <sys/socket.h>
#include <sys/ioctl.h>

//#import <net/if_arp.h>
#import <net/if_dl.h>
#if TARGET_IPHONE_SIMULATOR
#import <netinet/if_ether.h>
#else
#import "if_ether.h"
#endif

//ping
#include <netinet/ip.h>

#if TARGET_IPHONE_SIMULATOR
#include <netinet/ip_icmp.h>
#else
#include "ip_icmp.h"
#endif
//#include <net/ethernet.h>

@implementation NetUtils
+ (NSString *) hostToIp:(NSString *)host{
    struct hostent *hosts = gethostbyname([host UTF8String]);
    NSAssert(hosts, @"gethostbyname 失败");
    struct in_addr **list = (struct in_addr **)hosts->h_addr_list;
    NSString *addressString = [NSString stringWithCString:inet_ntoa(**list) encoding:NSUTF8StringEncoding];
    return addressString;
}

+ (NSString *) hostToIp2:(NSString *)host{
    struct addrinfo *answer;
    int ret = getaddrinfo([host UTF8String], NULL,NULL, &answer);
    NSAssert(ret == 0, @"getaddrinfo出错");
    
    struct addrinfo *curr;
    char ipStr[16];
    //和gethostbyname一样的
    for (curr = answer; curr != NULL; curr = curr->ai_next) {
        inet_ntop(AF_INET, &(((struct sockaddr_in *)(curr->ai_addr))->sin_addr), ipStr, 16);
    }
    freeaddrinfo(answer);
    freeaddrinfo(curr);
    return [NSString stringWithUTF8String:ipStr];
}

+ (NSString *) localIp{
    struct ifaddrs *interfaces = NULL;
    NSString *address = @"";
    int success = getifaddrs(&interfaces);
    NSAssert(success == 0, @"getifaddrs失败");
    struct ifaddrs *interface = interfaces;
    while (interface != NULL) {
        if( interface->ifa_addr->sa_family == AF_INET) {//必须要, 有可能是AF_LINK和AF_INET6
            NSLog(@"是");
            //只考虑这一种情况, 一般就一个
            if ([[NSString stringWithUTF8String:interface->ifa_name] hasPrefix:@"en"]) {//en0和 en1都, 0是有线, 真机还没测试
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interface->ifa_addr)->sin_addr)];
                NSLog(@"%@",address);
            }else{
                NSLog(@"%@", [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interface->ifa_addr)->sin_addr)]);
                NSLog(@"%@", [NSString stringWithUTF8String:interface->ifa_name]);
            }
        }else{//不是因特网协议簇, 搞不懂
            NSLog(@"%d=%d", interface->ifa_addr->sa_family,AF_INET);
        }
        interface = interface->ifa_next;
    }
    freeifaddrs(interfaces);
    return address;
}

+ (NSString *) localIp2{
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct ifreq ifr;//ifreq专门用于存储ioctl信息
    strcpy(ifr.ifr_name, "en0");
    ioctl(sock, SIOCGIFADDR, &ifr);
    close(sock);
    struct sockaddr_in *addr_in = (struct sockaddr_in *) &ifr.ifr_addr;
    char *ip = inet_ntoa(addr_in->sin_addr);
    return [NSString stringWithUTF8String:ip];
}

+ (NSString *) broadcastIp{
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct ifreq ifr;//ifreq专门用于存储ioctl信息
    strcpy(ifr.ifr_name, "en0");
    ioctl(sock, SIOCGIFBRDADDR, &ifr);
    close(sock);
    struct sockaddr_in *addr_in = (struct sockaddr_in *) &ifr.ifr_addr;
    char *ip = inet_ntoa(addr_in->sin_addr);
    return [NSString stringWithUTF8String:ip];
}

+ (NSString *) netMask{
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct ifreq ifr;//ifreq专门用于存储ioctl信息
    strcpy(ifr.ifr_name, "en0");
    ioctl(sock, SIOCGIFNETMASK, &ifr);
    close(sock);
    
    struct sockaddr_in *addr_in = (struct sockaddr_in *) &ifr.ifr_addr;
    char *ip = inet_ntoa(addr_in->sin_addr);
    return [NSString stringWithUTF8String:ip];
}

+ (NSString *)ip2HostIp:(NSString *)ip{
    struct in_addr origin;
    inet_aton([ip UTF8String], &origin);
    struct in_addr des;
    des.s_addr = inet_lnaof(origin);//提取主机id
    return [NSString stringWithUTF8String:inet_ntoa(des)];
}

+ (NSString *) ip2Net:(NSString *)ip{
    struct in_addr origin;
    inet_aton([ip UTF8String], &origin);
    struct in_addr des;
    des.s_addr = inet_netof(origin); //提取主机id
    return [NSString stringWithUTF8String:inet_ntoa(des)];
}

+ (NSString *) mac{//和路由套接字差不多, 直接取内核
    int mgmtInfoBase[6] = {CTL_NET,// Request network subsystem
        AF_ROUTE,// Routing table info
        0,
        AF_LINK,// Request link layer information
        NET_RT_IFLIST,// Request all configured interfaces
        if_nametoindex("en0")//此处还需斟酌,取的就是ifconfig里面的那一堆东西的第几个, 我看了, 确实是从1开始,0是有限, 1是无线
    };
    NSAssert(mgmtInfoBase[5] > 0, @"if_nametoindex出错");
    // Get the size of the data available (store in len)
    size_t              length;
    NSAssert(sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) >= 0, @"sysctl取长度出错");
    char* msgBuffer = malloc(length);
    NSAssert(sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) >= 0, @"sysctl放到buffer出错");
    
    // Map to link-level socket structure, 下面的arp也是一样的
     struct sockaddr_dl  *socketStruct = (struct sockaddr_dl *) ((struct if_msghdr *) msgBuffer + 1);
    unsigned char       macAddress[6];
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    NSString *macAddressString = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    // Release the buffer memory
    free(msgBuffer);
    return macAddressString;
}

+ (NSDictionary *)_wifiInfo{
    CFArrayRef myRef = CNCopySupportedInterfaces();
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myRef, 0));
    NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
    return dict;
}

+ (NSString *) ssid{
#if TARGET_IPHONE_SIMULATOR
    return @"模拟器不支持";
#elif TARGET_OS_IPHONE
    NSDictionary *dict = [self _wifiInfo];
    return dict[@"SSID"];
#endif
}

+ (NSString *) bssid{
#if TARGET_IPHONE_SIMULATOR
    return @"模拟器不支持";
#elif TARGET_OS_IPHONE
    NSDictionary *dict = [self _wifiInfo];
    return dict[@"BSSID"];
#endif
}

+ (CurrentNetworkStatus) currentNetWorkStatus{
    struct sockaddr_in addr ;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_len = sizeof(addr);
    SCNetworkReachabilityRef reachabilityRef  = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&addr);
    
    NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
    
    CurrentNetworkStatus currentStatus = NetworkStatusNotReachable;
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)//这个位是0
    {
        return NetworkStatusNotReachable;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        currentStatus = NetworkStatusReachableViaWiFi;
    }
    
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		currentStatus = NetworkStatusReachableViaWWAN;
	}
    
    return currentStatus;
}

+ (NSString *) gateway{
    int sockfd = socket(AF_ROUTE,SOCK_RAW,0);
    int rtm_msglen = sizeof(struct rt_msghdr) + sizeof(struct sockaddr_in);
    struct rt_msghdr *rtm = calloc(rtm_msglen, 1);
    //(struct rt_msghdr *)buf;
    rtm->rtm_msglen = rtm_msglen;
    rtm->rtm_version = RTM_VERSION;
    rtm->rtm_type = RTM_GET;
    rtm->rtm_addrs = RTA_DST;//是1,2,4,8,16这 种的累加值
    rtm->rtm_pid = getpid();
    rtm->rtm_seq = 9999;
    struct sockaddr_in *sin = (struct sockaddr_in *)    (rtm +1);//在struct rt_msghdr后面就是struct sockaddr_in
    sin->sin_len = sizeof(struct sockaddr_in);
    sin->sin_family = AF_INET;
    inet_aton("114.215.128.233",  &(sin->sin_addr));
    write(sockfd, rtm, rtm->rtm_msglen);
    free(rtm);
    
    uint ressultBufLen = sizeof(struct rt_msghdr) + 512;//接受缓存要比之前那个rtm->rtm_msglen长,因为要返回一堆地址, 网关掩码等
    struct rt_msghdr *result_rtm = calloc(ressultBufLen, 1);
    ssize_t n = read(sockfd, result_rtm, ressultBufLen);
    printf("read返回的长度 %zd,sa长度%zd,addr%d",n,n-sizeof(struct rt_msghdr),result_rtm->rtm_addrs);
    struct sockaddr *sa = (struct sockaddr *)(result_rtm + 1);//后面这一堆sockaddr的头指针
    struct sockaddr_in *gateway = (struct sockaddr_in *)((char  *)sa + sa->sa_len);//第一个是RTAX_DST, 我们只要网关
    free(result_rtm);
    return [NSString stringWithUTF8String:inet_ntoa(gateway->sin_addr)];
}

+ (NSString *) gateway2{
    int mib[6] = {CTL_NET,
        PF_ROUTE,//其实就是af_route的define
        0, AF_INET,
        NET_RT_FLAGS, RTF_GATEWAY};
    size_t len;
    NSAssert(sysctl(mib,sizeof(mib)/sizeof(int), 0, &len, 0, 0) >= 0, @"取长度出错");
//    NSLog(@"sysctl buf长度%zd",len);
    char *buf = calloc(len, 1);
    NSAssert(sysctl(mib,sizeof(mib)/sizeof(int), buf, &len, 0, 0) >= 0, @"取长度出错");
//    NSLog(@"实际内容长度%zd",len);
    struct rt_msghdr *rtptr = (struct rt_msghdr *)buf;//routeptr, 后面解析数据就一样的了
    struct sockaddr *sa = (struct sockaddr *)(rtptr + 1);
    struct sockaddr_in *gateway = (struct sockaddr_in *)((char  *)sa + sa->sa_len);//第一个是RTAX_DST, 我们只要网关
    free(rtptr);
//    NSLog(@"%s",inet_ntoa(gateway->sin_addr));
    return [NSString stringWithUTF8String:inet_ntoa(gateway->sin_addr)];
}

+ (NSString *) ip2Host:(NSString *)ip{
    struct in_addr ipAddr;//429140089
    inet_aton([ip UTF8String], &ipAddr);
    struct hostent *host = gethostbyaddr(&ipAddr, 4, AF_INET);
    if (host == NULL) {
        NSLog(@"err2 %@",ip);
        switch(h_errno){
            case HOST_NOT_FOUND:
                NSLog(@"找不到主机");
                break;
//            case NO_ADDRESS:
            case NO_DATA:
                NSLog(@"主机有效, 无ip");
                break;
            case NO_RECOVERY:
                printf("113\n");
                NSLog(@"有错");
                break;
            case TRY_AGAIN:
                NSLog(@"有错");
                break;
        }
        return nil;
    }
    return [NSString stringWithUTF8String:host->h_name];
}

+ (int) getServPortByName:(NSString *)name{
    struct servent *serv = getservbyname([name UTF8String], NULL);
    return ntohs(serv->s_port);
}
//http://stackoverflow.com/questions/2258172/how-do-i-query-the-arp-table-on-iphone
+(NSArray *) arpTable{
    int mib[6] = {CTL_NET,
        PF_ROUTE,
        0, AF_INET,
        NET_RT_FLAGS, RTF_LLINFO};
    size_t len;
    sysctl(mib, 6, NULL, &len, NULL, 0);
    char *buf = malloc(len);
    NSAssert(buf != NULL, @"malloc出错");
    sysctl(mib, 6, buf, &len, NULL, 0);
//    NSLog(@"arp表长度%zd",len);
    char *cur = buf;
    char *max = buf + len;
    NSMutableArray *arps = [NSMutableArray array];
    while (cur < max) {
        struct rt_msghdr *rtm = (struct rt_msghdr *)cur;
        struct sockaddr_inarp *sin = (struct sockaddr_inarp *)(rtm + 1);
        struct sockaddr_dl *sdl = (struct sockaddr_dl *)(sin + 1);
        unsigned char *cp = (unsigned char *)LLADDR(sdl);
        if (cp[5] != 0) {
            NSString *mAddr = [NSString stringWithFormat:@"ip=>%s mac: %x:%x:%x:%x:%x:%x",inet_ntoa(sin->sin_addr),cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
            [arps addObject:mAddr];
        }
        cur += rtm->rtm_msglen;
    }
    free(buf);
    return arps;
}
//icmp可能被防火墙干掉, 收不到返回
+ (BOOL) ping:(NSString *)ip{
    
    int bufSize = 1500;

    int sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    struct icmp *requestIcmp = malloc(bufSize);
    requestIcmp->icmp_type = ICMP_ECHO;
    requestIcmp->icmp_code = 0;
    requestIcmp->icmp_id = getpid();
    requestIcmp->icmp_seq = 1;//seq一般的ping程序是递增的
    requestIcmp->icmp_cksum = 0;
    struct addrinfo *resultInfo = NULL;
    
    int n = getaddrinfo([ip UTF8String], NULL, NULL, &resultInfo);
    if (n != 0 || resultInfo == NULL) {
        NSLog(@"解析ip出错%@",ip);
        return NO;
    }
//    NSAssert(n  == 0, @"解析ip出错");
    struct sockaddr *destAddr = resultInfo->ai_addr;
    ssize_t result = sendto(sockfd, requestIcmp, sizeof(struct icmp), 0, destAddr, sizeof(struct sockaddr));//发送icmp包
    if (result <= 0) {
        NSLog(@"发送icmp包出错");
        return NO;
    }
//    NSAssert(result > 0, @"发送icmp包出错");
//    NSLog(@"发送icmp包成功%zd",result);
    free(requestIcmp);
    freeaddrinfo(resultInfo);
    
    char recvbuf[bufSize],controlbuf[bufSize];
    struct iovec iov = {.iov_base = recvbuf,//最总要的就是这个buf
        .iov_len = sizeof(recvbuf)
    };
    struct sockaddr resultAddr;
    struct msghdr msg = {.msg_name = &resultAddr,//存储icmp包的地址
        .msg_iov = &iov,
        .msg_iovlen = 1,
        
        .msg_control = controlbuf,
        .msg_controllen = sizeof(controlbuf),
        
        .msg_namelen = sizeof(struct sockaddr),
    };
    
    if (fcntl(sockfd, F_SETFL, O_NONBLOCK) == -1){//io非阻塞
        NSAssert(NO, @"socket设置成非阻塞失败");
    }
    ssize_t recvn = -1;
    for (int i = 0 ; i < 5; i++) {
        recvn = recvmsg(sockfd, &msg, 0);
        if (recvn > 0) {
            NSLog(@"收到返回,总长度%zd",recvn);//只要收到返回就表示有了
            break;
        }else{
//            NSLog(@"没收到sleep0.3");
            usleep(100000);//0.3秒
        }
    }
    close(sockfd);
    return recvn > 0;//只到这里就可以了, 下面的都是解包的事情了
   }
@end
