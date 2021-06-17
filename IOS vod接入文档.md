## 腾讯云 X-P2P Vod IOS SDK 接入文档。

### 介绍

腾讯云X-P2P解决方案，可帮助用户直接使用经过大规模验证的直播、点播、文件分发服务，通过经商用验证的P2P服务大幅节省带宽成本，提供更优质的用户体验。开发者可通过SDK中简洁的接口快速同自有应用集成，实现IOS设备上的P2P加速功能。

传统CDN加速服务中，客户端向CDN发送HTTP请求获取数据。在腾讯云X-P2P服务中，SDK可以视为下载代理模块，客户端应用将HTTP请求发送至SDK，SDK从CDN或其他P2P节点获取数据，并将数据返回至上层应用。SDK通过互相分享数据降低CDN流量，并通过CDN的参与，确保了下载的可靠性。

SDK支持多实例，即支持同时开启多个点播p2p。

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

##### xresid

xresid是资源id，由业务层给出，必须保证能唯一标识这个视频文件，相同的xresid才能互相p2p。比如根据url path等计算md5并转hex得出。  
如果业务层没有传入xresid，sdk内部默认根据url path生成xresid。

##### 播放控制（start/stop）

- start 启动一个点播p2p：

首先拿到点播视频的url，通过以下方式拼接出p2pUrl，通过http请求p2pUrl即可。

```
    // 例如：url = http://domain/path/to/some.file?params=xxx
    // 变成：p2pUrl = [XNet proxyOf:@"xdfs.p2p.com"]/domain/path/to/some.file?params=xxx&xresid=resource_id&xmode=ordered

    NSString *host = @"xdfs.p2p.com";
    if ([originUrl rangeOfString:@"m3u8"].location != NSNotFound) {
        host = @"hls.vod.p2p.com";
    }
    
    // 业务层给出xresid
    NSString *xresid = resource_id;
    NSString* p2pUrl = [originUrl stringByReplacingOccurrencesOfString:@"http://" withString: [XNet proxyOf:host]];
    p2pUrl = [[p2pUrl stringByAppendingString:@"?xresid="] stringByAppendingString:xresid];
    if (host isEqualToString:@"xdfs.p2p.com") {
        // xmode是sdk提供的请求方式，点播需要使用ordered方式。hls不需要设置xmode
        NSString *xmode = @"ordered";
        p2pUrl = [[p2pUrl stringByAppendingString:@"&xmode="] stringByAppendingString:xmode];
    }
```

sdk中默认是以http协议去请求cdn，如果要求https，需要在url中添加参数"xhttps=1"。

需要注意，这里区分出单码率视频格式和多码率视频格式。  
单码率格式：mp4/flv等单个文件的视频格式。    
多码率格式：hls/dash。

对于单码率格式，统一使用host是"xdfs.p2p.com"。   
对于hls格式，使用host是"hls.vod.p2p.com"，只需对m3u8文件的url根据上述方式拼接即可，其中的ts文件的url已经由sdk内部处理并写入m3u8文件中。
如果有防盗链需求，照常添加到url的query部分即可（m3u8的url和ts的url都可以）。

==start的http响应状态码==

一个start请求，http响应的状态码有几种可能：

1. 200或206：p2p启动成功。
2. 400: start的url的参数缺失，比如缺失了xresid。
3. 404: start的url的host错了。
4. 302: 这个资源当前无法p2p，返回302（Location为cdn url）。

关于为什么当前资源无法p2p而返回302，具体原因可以在http响应的body中查看。     
如果body中的code是404，说明这个资源正在准备中，稍后才能p2p。对于每个新的资源，sdk需要借助服务端下载并计算出资源的校验码，以保证数据在p2p过程中的正确性。    
服务端下载资源会有一定耗时，过程中这个资源无法p2p。对于较热的资源，建议客户联系我们提前计算好这个资源的校验码，以加快p2p过程。

- stop 关闭一个点播p2p：

断开start时启动的http连接即可。

- **resume(重要) 恢复xp2p sdk**

从后台回到前台时必须调用resume，否则在播放器在后台阶段iOS可能会关闭链接，此时向sdk发起请求会出错。需要保证在播放器重新发起请求之前调用resume.

```
    [XNet resume];
```

#### 设置是否允许流量上传

sdk中默认允许流量上传，对于移动网络类型，用户可能不希望有流量上传，我们提供http接口可以设置，业务根据需要自行设置。

```
NSString* url = [[XNet proxyOf:@"xdfs.p2p.com"] stringByAppendingString:@"feature?upload=0"];
http request
```

如上拼接出url，用http get请求即可。注意是"xdfs.p2p.com"，不能是其他，upload=0表示不允许上传，upload=1表示允许上传。     
http请求到sdk，会响应json展示设置结果，示例:

```
{"ret":0,"msg":"ok","download":true,"upload":false}
```

#### 流量统计

目前可通过运营网站查看，后续sdk会提供接口方便实时查询单机统计。

#### 播放器缓存

建议播放器缓存设置一个比较小的值，建议15s以内。