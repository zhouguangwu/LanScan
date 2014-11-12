//
//  Nginx.h
//  Utils
//
//  Created by wayos-ios on 11/11/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Nginx;
@protocol NginxDelegate
- (void) nginx:(Nginx *)nginx didRecevidData:(NSData *)data;
@end

@interface Nginx : NSObject
-(void) start;
-(void) stop;
-(BOOL) ing;
@property id<NginxDelegate> delegate;
@end
