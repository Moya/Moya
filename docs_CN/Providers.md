# (供应者) Providers

当使用 Moya 时, 你通过 `MoyaProvider` 对象进行所有 API 请求，并把指定要调用哪个`Endpoint` 的 `enum` 的值传递给它。在你设置了 [Endpoint](Endpoints.md) 之后, 基本用法实际上配置完毕了:

```swift
let provider = MoyaProvider<MyService>()
```

在如此简单的设置之后你就可以直接使用了:

```swift
provider.request(.zen) { result in
    // `result` is either .success(response) or .failure(error)
}
```

到此完毕! `request()` 方法返回一个 `Cancellable` ，它只有 `cancel()` 这个公开的方法，你可以通过调用这个方法来取消请求。更多关于 `Result` 的信息查看 [Examples](Examples) 

记住,  把 `target` 和 `provider` 放在*哪儿*完全取决于你自己。你可以查看 [Artsy的实现](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/ArtsyAPI.swift) 的例子.

但是别忘了持有 `provider`，如果不这样做， `provider` 就会被释放掉，你将会在 `response` 上看到一个 `-999 "canceled"` 错误。

## 高级用法

为了解释 `MoyaProvider` 所有的配置选项我们将会按照下面的小节一个一个的来解析 。

### （endpoint闭包） endpointClosure :

  `MoyaProvider` 构造器的第一个(可选的)参数是一个
　`endpoints` 闭包, 它负责把您的 `enum` 值映射成一个 `Endpoint` 实例对象。 让我们看看它是什么样子的。

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint in
    let url = URL(target: target).absoluteString
    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task)
}
let provider = MoyaProvider(endpointClosure: endpointClosure)
```

注意在这个 `MoyaProvider` 的构造器中我们不需要再指定泛型 ，因为 Swift 将会自动从 `endpointClosure` 的类型中推断出来。 非常灵巧!

您有可能已经注意到了`URL(target:)` 构造器, Moya 提供了一个便利扩展来从任意  `TargetType` 中创建 `URL` 。

这个 `endpointClosure` 就像你看到的这样简单. 它其实也是 Moya 的默认实现， 这个实现存储在 `MoyaProvider.defaultEndpointMapping` .
如果想自定义 `endpointClosure` ，请查看 [Endpoints](Endpoints.md) 文档的 _为什么_ 部分。

### （请求闭包） requestClosure :

下一个可选的初始化参数是 `requestClosure` ，它把一个 `Endpoint` 转换成一个实际的  `URLRequest` 。 同样的，查看 [Endpoints](Endpoints.md)
文档了解为什么及如何来做这个 。

### （ stub 闭包） stubClosure :

下一个可选的初始化参数是提供一个 `stubClosure` 。这个闭包返回 `.never` (默认的)， `.immediate` 或者可以把 stub 请求延迟指定时间的 `.delayed(seconds)` 三个中的一个。 例如， `.delayed(0.2)` 可以把每个 stub 请求延迟 0.2s 。 这个在单元测试中来模拟网络请求是非常有用的。

更棒的是如果你需要对请求进行区别性的 stub ，那么你可以使用自定义的闭包。

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { target: MyTarget -> Moya.StubBehavior in
    switch target {
        /* Return something different based on the target. */
    }
})
```

但通常情况下，如果你希望所有目标都有同样的 stub 行为，在 `MoyaProvider`中有三个静态方法可以使用。

```swift
MoyaProvider.neverStub
MoyaProvider.immediatelyStub
MoyaProvider.delayedStub(seconds)
```

所以，在上面的示例上，如果你希望为所有的 target 立刻进行 stub 行为，下面的两种方式都可行 。

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { (_: MyTarget) -> Moya.StubBehavior in return .immediate })
let provider = MoyaProvider<MyTarget>(stubClosure: MoyaProvider.immediatelyStub)
```

### （管理器） session :

接下来就是 `session` 参数，默认会获得一个通过基本配置进行初始化的自定义的 `Alamofire.Session` 实例对象

```swift
final class func defaultAlamofireSession() -> Session {
    let configuration = URLSessionConfiguration.default
    configuration.headers = .default
    
    return Session(configuration: configuration, startRequestsImmediately: false)
}
```

这儿只有一个需要注意的事情：由于在 AF 中创建一个 `Alamofire.Request` 对象时默认会立即触发请求，即使为单元测试进行 "stubbing" 请求也一样。 因此在Moya中, `startRequestsImmediately` 属性被默认设置成了 `false` 。

如果你需要自定义自己的 `session` ， 比如说创建一个 SSL pinning 并且添加到`session` 中，所有请求将通过自定义配置的 `session` 进行路由。

```swift
let serverTrustManager = ServerTrustManager(evaluators: ["example.com": PinnedCertificatesTrustEvaluator()])

let session = Session(
    configuration: configuration, 
    startRequestsImmediately: false, 
    serverTrustManager: serverTrustManager
)

let provider = MoyaProvider<MyTarget>(session: session)
```

### （插件） plugins :

最后, 你可能也提供一个 `plugins` 数组给provider。这些插件会在请求被发送前及响应收到后被执行。 Moya 已经提供了一些插件: 一个是网络活动( `NetworkActivityPlugin` )，一个是 Log 插件 ( `NetworkLoggerPlugin` )，还有一个是 [HTTP Authentication](Authentication.md) 。

例如您可以通过传递 `[NetworkLoggerPlugin()]` 给 `plugins` 参考来开启日志记录。插件也是可配置的，比如说 `NetworkActivityPlugin` 需要一个 `networkActivityClosure` 参数。可配置的插件实现类似这样的:

```swift
public final class NetworkActivityPlugin: PluginType {

    public typealias NetworkActivityClosure = (_ change: NetworkActivityChangeType, _ target: TargetType) -> Void
    let networkActivityClosure: NetworkActivityClosure

    public init(networkActivityClosure: @escaping NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public func willSend(_ request: RequestType, target: TargetType) {
        networkActivityClosure(.began, target)
    }

    /// Called by the provider as soon as a response arrives, even if the request is canceled.
    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        networkActivityClosure(.ended, target)
    }
}
```

`networkActivityClosure` 是一个当网络请求开始或结束时进行调用的闭包。 这个和 [network activity indicator](https://github.com/thoughtbot/BOTNetworkActivityIndicator) 可以结合起来使用。
注意这个闭包的签名是 `(change: NetworkActivityChangeType) -> ()` ，
所以只有当请求是 `.began` 或者 `.ended`（没有提供任何关于网络请求的细节） 时才会被调用。
