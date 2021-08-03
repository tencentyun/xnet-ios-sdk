# 腾讯云Proxy IOS SDK 接入文档

## 一、介绍

腾讯云Proxy解决方案，可帮助用户直接使用经过大规模验证的代理服务，通过代理请求资源，提供更优质的用户体验。开发者可通过SDK中简洁的接口快速同自有应用集成，实现Android设备上的proxy功能。

传统CDN加速服务中，客户端向CDN发送HTTP请求获取数据。在腾讯云Proxy服务中，SDK可以视为下载代理模块，客户端应用将HTTP请求发送至SDK，SDK从CDN获取数据，并将数据返回至请求应用，支持自定义功能如解密等。


## 二、接入SDK

### ios当前支持的架构
armv7 armv7s arm64

### 应用配置
腾讯云对接人员会提供iOS项目的Bundle identifier，并索取App ID、App Key、App Secret Key，如以下形式：(没有时可以为空字符串)
```
Bundle identifier：com.qcloud.helloworld
NSString *appID = @"5919174f79883b4648a90bdd";
NSString *key = @"3qRcwO0Zn1Gm8t2O";
NSString *secret = @"Ayg29EDt1AbCXJ9t6HoQNbZUf6cPuV5J";
```

### 具体步骤

- 解压解压xnet.zip并得到xnet.framework，并在项目中引用

- 在App启动时初始化XNet

首先需要初始化 sdk，最好在app启动后就作初始化。

```
// Example: 程序的入口AppDelegate.m
#import "AppDelegate.h"
#import <xnet/XNet.h>
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // do something other...

    // enableDebug接口调用可以开启SDK log的打印，不调用该接口，log打印默认不开启
    // [XNet enableDebug]

    NSString *appID = @"your app id";
    NSString *key = @"your app key";
    NSString *secret = @"your app secret";
    [XNet initWith:appID appKey:key appSecretKey:secret];

    return YES;
}

@end
 ```

- 访问代理服务

首先拿到请求的url，通过以下方式拼接出proxyUrl，通过http请求proxyUrl即可。

```
    // 例如：http://domain/path/to/resource.m3u8?params=xxx
    // 变成：http://IP:Port/Server/domain/path/to/resource.m3u8?params=xxx
    // IP指内网ip，Port是sdk监听的端口
    // Server是服务的名字,代理服务的名字固定为"hls.proxy.com

    NSString *originUrl = @"http://domain/path/to/resource.m3u8?params=xxx";
    // IP：本机是127.0.0.1，内网是其它获取到的ip
    NSString* IP = "127.0.0.1"; 
    NSString* proxyHost = [NSString stringWithFormat:@"%@%@:%@/%@/", @"http://", IP, [XNet port], @"hls.proxy.com"];
    NSString* proxyUrl = [originUrl stringByReplacingOccurrencesOfString:@"http://" withString: proxyHost];
    
```

url的params可以配置拉流的信息，如密钥，http模式
```
        proxyUrl = [proxyUrl stringByAppendingString:@"&xkey=${your_key}"]; // 密钥为hex格式字符串
		proxyUrl = [proxyUrl stringByAppendingString:@"&xiv=${your_iv}"];   // iv为hex格式字符串
		proxyUrl = [proxyUrl stringByAppendingString:@"&xscheme=https"];    // 源流scheme, 默认为http, 可以设置为https
```

- stop 关闭一个请求：

断开start时启动的http连接即可。

- **resume(重要) 恢复 sdk**

从后台回到前台时必须调用resume，否则在程序在后台阶段iOS可能会关闭链接，此时向sdk发起请求会出错。需要保证在播放器重新发起请求之前调用resume.

```
    [XNet resume];
```

## 三、API
SDK接口除初始化接口, 其余接口均由http实现, 请求格式为`http:://IP:${XNet.port}/Server/${func}?${param}`

### 设置密钥
- 描述: 设置代理server的密钥

- 方法: POST

- 路径: /hls.proxy.com/key?xkey=key_hex&xiv=iv_hex

- 请求参数:

  |  参数名称   | 必选 | 类型 | 说明 |
        |  ----  | ----   | ---- | ----  |
  | xkey  | 是 | string | 密钥为hex字符串，如：30354136373143363641454645413132 |
  | xiv  | 否 | string | iv为hex字符串，如：30354136373143363641454645413132 |

- 返回参数:

  |  返回码   | 说明 |
        |  ----  | ----  |
  | 200  | 设置成功 |
  | 404  | 设置失败, server不存在 |

- 请求样例

  http://127.0.0.1:16080/hls.proxy.com/key?xkey=30354136373143363641454645413132&xiv=30354136373143363641454645413132

