//
//  XNet.m
//  RTMPiOSDemo
//
//  Created by yanyin on 2019/10/26.
//  Copyright © 2019 tencent. All rights reserved.
//

#import "XNet.h"
#import <Foundation/Foundation.h>
#import <sys/signal.h>
#import "TencentXP2P/XP2PService.h"

__weak static id<Logger> _loggger = nil;

@implementation XNet

static NSString* host = @"";
static dispatch_once_t onceToken;

+ (int)initWith:(NSString*)appId appKey:(NSString*)appKey appSecretKey:(NSString*)appSecretKey {
    NSLog(@"[TencentXP2P] [qcloud] start init TencentXP2P SDK");
    signal(SIGPIPE, SIG_IGN);

    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* cacheDirectory = [NSSearchPathForDirectoriesInDomains(
        NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* packageName = [infoDictionary objectForKey:@"CFBundleIdentifier"];

    XP2PService::init([appId UTF8String], [appKey UTF8String], [appSecretKey UTF8String],
                      [packageName UTF8String], [cacheDirectory UTF8String]);

    host = [[NSString alloc] initWithCString:(const char*)XP2PService::host().c_str()
                                    encoding:NSASCIIStringEncoding];
    
    dispatch_once(&onceToken, ^{
        NSString * componentId = @"fdd82139ea";
        NSString * version = [XNet version];
        if (componentId && version) {
            NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
            // 读取已有信息并记录
            NSDictionary * dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"BuglySDKInfos"];
            if (dict) {
                [dictionary addEntriesFromDictionary:dict];
            }
            // 添加当前组件的唯⼀标识和版本
            [dictionary setValue:version forKey:componentId];
            // 写⼊更新的信息
            [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithDictionary:dictionary] forKey:@"BuglySDKInfos"];
        }
    });
    return EXIT_SUCCESS;
}

+ (NSString*)version {
    return [[NSString alloc] initWithCString:(const char*)XP2PService::version().c_str()
                                    encoding:NSASCIIStringEncoding];
}

+ (void)enableDebug {
    XP2PService::setLogger(
                           [](const char* msg) { NSLog(@"[debug][XP2P]%@", [NSString stringWithUTF8String:msg]); },
                           [](const char* msg) { NSLog(@"[info][XP2P]%@", [NSString stringWithUTF8String:msg]); },
                           [](const char* msg) { NSLog(@"[trace][XP2P]%@", [NSString stringWithUTF8String:msg]); },
                           [](const char* msg) { NSLog(@"[warn][XP2P]%@", [NSString stringWithUTF8String:msg]); },
                           [](const char* msg) { NSLog(@"[error][XP2P]%@", [NSString stringWithUTF8String:msg]); });
}

+ (void)disableDebug {
    XP2PService::setLogger(nullptr, nullptr, nullptr, nullptr, nullptr);
}

+ (void)alias:(NSString*)host of:(NSString*)name {
    XP2PService::alias([host UTF8String], [name UTF8String]);
}

+ (int)resume {
    XP2PService::resume();
    host = [[NSString alloc] initWithCString:(const char*)XP2PService::host().c_str()
                                    encoding:NSASCIIStringEncoding];
    return EXIT_SUCCESS;
}

+ (NSString*)host {
    return host;
}

+ (NSString*)proxyOf:(NSString*)domain {
    NSString* proxy = @"";
    if ([host length] > 0) {
        proxy = [[NSString alloc] initWithFormat:@"%@/%@/", host, domain];
    }
    return proxy;
}

@end
