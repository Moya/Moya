# (供应者)Providers

当使用Moya时, 您通过MoyaProvider实例进行所有API请求,并把指定要调用哪个Endpoint的enum的值传递给它。在你设置了 [Endpoint](Endpoints.md)之后, 基本用法实际上配置完毕了:

```swift
let provider = MoyaProvider<MyService>()
```

在如此简单的设置之后您就可以直接使用了:

```swift
provider.request(.zen) { result in
    // `result` is either .success(response) or .failure(error)
}
```

到此完毕! `request()` 方法返回一个`Cancellable`, 它有一个你可以取消request的公共的方法。 更多关于`Result`类型的的信息查看 [Examples](Examples) 

记住,  把target和provider放在*哪儿*完全取决于您自己。 您可以查看 [Artsy的实现](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/ArtsyAPI.swift)
的例子.

但是别忘了持有它的一个引用 . 如果它被销毁了你将会在response上看到一个 `-999 "canceled"` 错误 。

## 高级用法

为了解释 `MoyaProvider`所有的配置选项我们将会按照下面的小节一个一个的来解析 。

### （endpoint闭包）endpointClosure:

  `MoyaProvider` 构造器的第一个(可选的)参数是一个
endpoints闭包, 它负责把您的enum值映射成一个`Endpoint`实例对象。 让我们看看它是什么样子的。

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint in
    let url = URL(target: target).absoluteString
    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task)
}
let provider = MoyaProvider(endpointClosure: endpointClosure)
```

注意在这个`MoyaProvider`的构造器中我们不再有指定泛型 ，因为Swift将会自动从`endpointClosure`的类型中推断出来。 非常灵巧!

您有可能已经注意到了`URL(target:)` 构造器, Moya 提供了一个便利扩展来从任意 `TargetType`中创建 `URL`。

这个`endpointClosure`就像您看到的这样简单. 它其实也是Moya的默认实现， 这个实现存储在 `MoyaProvider.defaultEndpointMapping`.
查看 [Endpoints](Endpoints.md) 文档来查看 _为什么_ 您可能想自定义这个。

### （请求闭包）requestClosure:

下一个初始化参数是`requestClosure`,它分解一个`Endpoint` 成一个实际的 `URLRequest`. 同样的, 查看 [Endpoints](Endpoints.md)
文档了解为什么及如何来做这个 。

### （stub闭包）stubClosure:

下一个选择是来提供一个`stubClosure`。这个闭包返回 `.never` (默认的), `.immediate` 或者可以把stub请求延迟指定时间的`.delayed(seconds)`三个中的一个。 例如, `.delayed(0.2)` 可以把每个stub 请求延迟0.2s. 这个在单元测试中来模拟网络请求是非常有用的。

更棒的是如果您需要对请求进行区别性的stub，那么您可以使用自定义的闭包。

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { target: MyTarget -> Moya.StubBehavior in
    switch target {
        /* Return something different based on the target. */
    }
})
```

但通常情况下，您希望所有目标都有同样的stub行为。在 `MoyaProvider`中有三个静态方法您可以使用。

```swift
MoyaProvider.neverStub
MoyaProvider.immediatelyStub
MoyaProvider.delayedStub(seconds)
```

所以,在上面的示例上,如果您希望为所有的target立刻进行stub行为，下面的两种方式都可行 。

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { (_: MyTarget) -> Moya.StubBehavior in return .immediate })
let provider = MoyaProvider<MyTarget>(stubClosure: MoyaProvider.immediatelyStub)
```

### （管理器）manager:

接下来就是`manager`参数. 默认您将会获得一个基本配置的自定义的`Alamofire.Manager`实例对象

```swift
public final class func defaultAlamofireManager() -> Manager {
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders

    let manager = Alamofire.Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}
```

这儿只有一个需要注意的事情: 由于在AF中创建一个`Alamofire.Request`默认会立即触发请求，即使为单元测试进行  "stubbing" 请求也一样。 因此在Moya中, `startRequestsImmediately` 属性被默认设置成了 `false` 。

如果您喜欢自定义自己的 manager, 比如, 添加SSL pinning, 创建一个并且添加到manager,
所有请求将通过自定义配置的manager进行路由.

```swift
let policies: [String: ServerTrustPolicy] = [
    "example.com": .PinPublicKeys(
        publicKeys: ServerTrustPolicy.publicKeysInBundle(),
        validateCertificateChain: true,
        validateHost: true
    )
]

let manager = Manager(
    configuration: URLSessionConfiguration.default,
    serverTrustPolicyManager: ServerTrustPolicyManager(policies: policies)
)

let provider = MoyaProvider<MyTarget>(manager: manager)
```

### 插件:

最后, 您可能也提供一个`plugins`数组给provider。 这些插件会在请求被发送前及响应收到后被执行。 Moya已经提供了一些插件: 一个是 网络活动(`NetworkActivityPlugin`),一个是记录所有的 网络活动 (`NetworkLoggerPlugin`), 还有一个是 [HTTP Authentication](Authentication.md).

例如您可以通过传递 `[NetworkLoggerPlugin()]` 给 `plugins`参考来开启日志记录 。注意查看也可以配置的, 比如，已经存在的 `NetworkActivityPlugin` 需要一个 `networkActivityClosure` 参数. 可配置的插件实现类似这样的:

```swift
public final class NetworkActivityPlugin: PluginType {

    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()
    let networkActivityClosure: NetworkActivityClosure

    public init(networkActivityClosure: NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public func willSend(request: RequestType, target: TargetType) {
        networkActivityClosure(change: .began)
    }

    /// Called by the provider as soon as a response arrives
    public func didReceive(data: Data?, statusCode: Int?, response: URLResponse?, error: ErrorType?, target: TargetType) {
        networkActivityClosure(change: .ended)
    }
}
```

`networkActivityClosure` 是一个当网络请求开始或结束时提供通知的闭包。 这个和 [network activity indicator](https://github.com/thoughtbot/BOTNetworkActivityIndicator)一起来用是非常有用的。
注意这个闭包的签名是 `(change: NetworkActivityChangeType) -> ()`,
所以只有当请求是`.began` 或者`.ended`（您没有提供任何关于网络请求的细节） 时您才会被通知。
