//
//  Nginx.m
//  Utils
//
//  Created by wayos-ios on 11/11/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import "Nginx.h"
#import "netinet/in.h"
#import "arpa/inet.h"
////子线程用全部变量有问题, 改成private变量
#define kRequestBuffLen 1024*300
@interface Nginx (){
    int _sockfd;
}

@end
@implementation Nginx
- (instancetype) init{
    if (self = [super init]) {
        _sockfd = -1;
    }
    return self;
}

- (void) start{
    //构建sock的addr
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(8888);
    //把addr弄到socket上面去
    _sockfd = socket(AF_INET, SOCK_STREAM, 0);
    assert(_sockfd > 0);
    NSLog(@"绑定socket=%d",_sockfd);
    int temp = bind(_sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
    assert(temp != -1);
    temp = listen(_sockfd, 1);//这种不能监听多个
    assert(temp == 0);
    while (1) {
        struct sockaddr_in client_addr;
        int client_len = sizeof(client_addr);
        NSLog(@"等待客户端连接");
        int client_sockfd = accept(_sockfd, (struct sockaddr *)&client_addr, (socklen_t *)&client_len);
        NSLog(@"客户端信息ip:=%s,port:%d,fd=%d \n",inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port),client_sockfd);
        //close后accept返回-1
        if (client_sockfd == -1) {//close了
            return;
        }
        char buff[kRequestBuffLen] = {0};//最大一M
        long len = recvfrom(client_sockfd, buff, sizeof(buff), 0, NULL, NULL);

        NSLog(@"len=%ld,buf=%s\n",len,buff);

        if (buff[0] == 'G' && buff[1] == 'E' && buff[2] == 'T') {
            //显示上传控件
            NSString *response = @"HTTP/1.1 200 OK\nServer: nginx/1.6.0\nContent-Type: text/html\n\n<form method='POST' enctype=\"multipart/form-data\"><input type='file' name=\"u_file\"/><input type='submit'/></form>";
            send(client_sockfd, response.UTF8String, response.length, 0);
            close(client_sockfd);
        }else{
            //post保存信息
            //先取文件名, 解包, 只考虑一个文件的问题
            NSData *fullData = [NSData dataWithBytes:buff length:len];
            NSString *boundary = [[NSString alloc] initWithData:[self _dataIn:fullData between:@"boundary=" and:@"\r\nContent-Length"] encoding:NSUTF8StringEncoding];
            NSLog(@"boundary=%@",boundary);
            
            //吧boundary中间的form弄出来
            NSData *formData = [self _dataIn:[NSData dataWithBytes:buff length:len] between:[NSString stringWithFormat:@"\r\n\r\n--%@",boundary] and:[NSString stringWithFormat:@"\r\n--%@--",boundary]];
            NSLog(@"渠道的formdata是");
            [self _pData:formData];

            NSData *fileNameData = [self _dataIn:formData between:@"filename=\"" and:@"\"\r\nContent-Type:"];
            NSLog(@"文件名: %@",[[NSString alloc] initWithData:fileNameData encoding:NSUTF8StringEncoding]);
            
            NSData *fileData = [self _dataIn:formData between:@"\r\n\r\n" and:nil];
            [self _pData:fileData];
            NSString *response = @"upload success";
            send(client_sockfd, response.UTF8String, response.length, 0);
            close(client_sockfd);
            
            [self.delegate  nginx:self didRecevidData:fileData];
        }

    }
}
- (void) _pData:(NSData *)data{
    const unsigned char *bytes = data.bytes;
//    for (int i = 0; i<data.length; i++) {
//        unsigned char c = bytes[i];
//        printf("%x ",c);
//    }
    NSLog(@"pdata--------\n\n");
    if (data.length > 200) {
        for (int i = 0; i<200; i++) {
            unsigned char c = bytes[i];
            printf("%c",c);
        }
        printf("\n");
        for (long i = data.length - 100; i<data.length; i++) {
            unsigned char c = bytes[i];
            printf("%c",c);
        }
    }else{
        for (int i = 0; i<data.length; i++) {
            unsigned char c = bytes[i];
            printf("%c",c);
        }
    }
    NSLog(@"------------------pdata");
}
- (BOOL) _isCStr:(const char *)buf hasOcPrefix: (NSString *)prefix{
//    if (*buf == '\r') {
//        
//    }
    for (int i = 0; i < prefix.length; i++) {
        if (buf[i] != prefix.UTF8String[i]) {
            return NO;
        }
    }
    return YES;
}
//前3个字符,非字符串智能用char *
- (NSData *)_dataIn:(NSData *)data between:(NSString *)begin and:(NSString *)end{
    const char *buff = data.bytes;
    assert(data.length > 0);
    assert(begin.length > 0);
    for (int i = 0; i <= data.length - begin.length; i++) {
        if ([self _isCStr:buff+i hasOcPrefix:begin]) {
            //在buf这个位置找到了,
            char result[data.length];
            NSLog(@"找到开始了,%d",i);
            bzero(result, data.length);
            if (end.length == 0) {
                NSLog(@"没有尾巴");
                return [NSData dataWithBytes:buff + i + begin.length length:data.length - i - begin.length];
            }else{
                for (int j = i+ (int)begin.length; j < data.length - end.length; j++) {//j不是相对于i的都是相对于0
                    if ([self _isCStr:(buff + j) hasOcPrefix:end]) {
                        NSLog(@"找到尾巴了%d",j);
                        return [NSData dataWithBytes:result length:j-i-begin.length];
                    }else{
                        //没完继续
                        result[j-i-begin.length] = buff[j];
                    }
                }
            }
        }
    }
    return nil;
}

- (BOOL) ing{
    NSLog(@"sockfd%d",_sockfd);
    return _sockfd > 0;
}

- (void) stop{
    close(_sockfd);
    _sockfd = -1;
}
@end
