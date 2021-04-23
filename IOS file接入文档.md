## 腾讯云 X-P2P File IOS SDK 接入文档。

### 介绍

腾讯云X-P2P解决方案，可帮助用户直接使用经过大规模验证的直播、点播、文件分发服务，通过经商用验证的P2P服务大幅节省带宽成本，提供更优质的用户体验。开发者可通过SDK中简洁的接口快速同自有应用集成，实现IOS设备上的P2P加速功能。

传统CDN加速服务中，客户端向CDN发送HTTP请求获取数据。在腾讯云X-P2P服务中，SDK可以视为下载代理模块，客户端应用将HTTP请求发送至SDK，SDK从CDN或其他P2P节点获取数据，并将数据返回至上层应用。SDK通过互相分享数据降低CDN流量，并通过CDN的参与，确保了下载的可靠性。

### 接入SDK

#### 腾讯云对接人员会提供iOS项目的Bundle identifier，并索取App ID、App Key、App Secret Key，如以下形式：

        Bundle identifier：com.qcloud.helloworld
        NSString *appID = @"your_app_id";
        NSString *key = @"$your_app_key";
        NSString *secret = @"$your_app_secret";

#### ios当前支持的架构

armv7 armv7s arm64

#### 具体步骤

- 解压解压xnet.zip并得到xnet.framework，并在项目中引用

- 在App启动时初始化XNet

首先需要初始化p2p sdk，最好在app启动后就作初始化。

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

##### 下载控制（start/stop）

- start 启动一个文件p2p：

目前只支持按顺序下载，外部业务通过http读取顺序下载到的数据并保存。后续会支持指定路径由sdk内部乱序下载并保存到指定路径中。    
首先拿到文件的url，通过以下方式拼接出p2pUrl，通过http请求p2pUrl即可。

```
    // 例如：url = http://domain/path/to/some.file?params=xxx
    // 变成：p2pUrl = [XNet proxyOf:@"xdfs.p2p.com"]/domain/path/to/some.file?params=xxx&xresid=resource_id&xmode=ordered

    NSString *host = @"xdfs.p2p.com";
    // xmode是sdk提供的请求方式，ordered是顺序下载。
    NSString *xmode = @"ordered";
    // xresid是资源id，必须保证能唯一标识这个视频文件，相同的xresid才能互相p2p。比如根据url path等计算md5并转hex得出。
    NSString *xresid = resource_id;
    NSString* p2pUrl = [originUrl stringByReplacingOccurrencesOfString:@"http://" withString: [XNet proxyOf:host]];
    p2pUrl = [[p2pUrl stringByAppendingString:@"?xresid="] stringByAppendingString:xresid];
    p2pUrl = [[p2pUrl stringByAppendingString:@"&xmode="] stringByAppendingString:xmode];
```

sdk中默认是以http协议去请求cdn，如果要求https，需要在url中添加参数"xhttps=1"。   
如果有防盗链需求，照常添加到url的query部分即可。

==start的http响应状态码==

一个start请求，http响应的状态码有几种可能：

1. 200或206：p2p启动成功。
2. 400: start的url的参数缺失，比如缺失了xresid。
3. 404: start的url的host错了。
4. 302: 这个资源当前无法p2p，返回302（Location为cdn url）。

关于为什么当前资源无法p2p而返回302，具体原因可以在http响应的body中查看。     
如果body中的code是404，说明这个资源正在准备中，稍后才能p2p。对于每个新的资源，sdk需要借助服务端下载并计算出资源的校验码，以保证数据在p2p过程中的正确性。    
服务端下载资源会有一定耗时，过程中这个资源无法p2p。对于较热的资源，建议客户联系我们提前计算好这个资源的校验码，以加快p2p过程。

- stop 关闭一个文件p2p：

断开start时启动的http连接即可。

- **resume(重要) 恢复xp2p sdk**

从后台回到前台时必须调用resume，否则在app在后台阶段iOS可能会关闭链接，此时向sdk发起请求会出错。需要保证在app重新发起请求之前调用resume.

```
    [XNet resume];
```

#### 流量统计

目前可通过运营网站查看，后续sdk会提供接口方便实时查询单机统计。
