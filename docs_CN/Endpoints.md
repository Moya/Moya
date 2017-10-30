# (端点)Endpoints

endpoint是Moya的半个内部数据结构，它最终被用来生成网络请求。 每个endpoint 都存储了下面的数据:

- url.
- HTTP 方法 (`GET`, `POST`, etc).
- HTTP 请求头.
- `Task` 用来区别 `upload`, `download` 和 `request`.
- sample response (为单元测试).

[Providers](Providers.md) 映射 [Targets](Targets.md) 成 Endpoints, 然后映射
Endpoints 到实际的网络请求。

有两种方式与Endpoints交互。

1. 当创建一个provider, 您可以指定一个从`Target` 到 `Endpoint`的映射.
1. 当创建一个provider, 您可以指定一个从`Endpoint` to `URLRequest`的映射.

第一个可能类似如下:

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let url = URL(target: target).absoluteString
    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task)
}
```

这实际上也Moya provide的默认实现。如果您需要一些定制或者创建一个在单元测试中返回一个非200HTTP状态的测试provide，这就是您需要自定义的地方。

注意 `URL(target:)` 的初始化, Moya 提供了一个从`TargetType`到`URL`的便利扩展。

第二个使用非常的少见。Moya试图让您不用操心底层细节。但是，如果您需要，它就在那儿。它的使用涉及的更深入些.。

让我们来看一个从Target到EndpointLet的灵活映射的例子。

## 从 Target 到 Endpoint

在这个闭包中，您拥有从`Target` 到 `Endpoint`映射的绝对权利，
您可以改变`task`, `method`, `url`, `headers` 或者 `sampleResponse`。
比如, 我们可能希望将应用程序名称设置到HTTP头字段中，从而用于服务器端分析。

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
    return defaultEndpoint.adding(newHTTPHeaderFields: ["APP_NAME": "MY_AWESOME_APP"])
}
let provider = MoyaProvider<GitHub>(endpointClosure: endpointClosure)
```

*注意头字段也可以作为[Target](Targets.md)定义的一部分。*

这也就意味着您可以为部分或者所有的endpoint提供附加参数。 比如, 假设 `MyTarget` 除了实际执行身份验证的值之外，其他的所有值都需要有一个身份证令牌，我们可以构造一个类似如下面的
`endpointClosure` 。

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)

    // Sign all non-authenticating requests
    switch target {
    case .authenticate:
        return defaultEndpoint
    default:
        return defaultEndpoint.adding(newHTTPHeaderFields: ["AUTHENTICATION_TOKEN": GlobalAppStorage.authToken])
    }
}
let provider = MoyaProvider<GitHub>(endpointClosure: endpointClosure)
```

太棒了.

请注意，我们可以依赖于Moya的现有行为，而不是替换它。 `adding(newHttpHeaderFields:)` 函数允许您依赖已经存在的Moya代码并添加自定义的值 。

Sample responses 是 `TargetType` 协议的必备部分。然而, 它们仅指定返回的数据。在Target-到-Endpoint的映射闭包中您可以指定更多对单元测试非常有用的细节。


Sample responses 有下面的这些值:

- `.networkError(NSError)` 当网络发送请求失败, 或者未能检索到响应 (比如 ，超时).
- `.networkResponse(Int, Data)` 这个里面 `Int` 是一个状态码， `Data` 是返回的数据.
- `.response(HTTPURLResponse, Data)` 这个里面 `HTTPURLResponse` 是一个 response ， `Data` 是返回的数据. 这个可用来完全的stub一个响应。


## Request 映射

我们先前已经提到过, 这个库的目标不是来提供一个网络访问的代码框架——那是Alamofire的事情。 
 Moya 是一种构建网络访问和为定义良好的网络目标提供编译时检查的方式。 您已经看到了如何使用`MoyaProvider`构造器中的`endpointClosure`参数把target映射成endpoint。这个参数让你创建一个  `Endpoint` 实例对象，Moya将会使用它来生成网络API调用。 在某一时刻,
`Endpoint` 必须被转化成 `URLRequest` 从而给到 Alamofire。
这就是 `requestClosure` 参数的作用.

`requestClosure` 是可选的,是最后编辑网络请求的时机 。 它有一个默认值`MoyaProvider.defaultRequestMapping`,
这个值里面仅仅使用了`Endpoint`的 `urlRequest` 属性 .

这个闭包接收一个`Endpoint`实例对象并负责调用把代表Endpoint的request作为参数的`RequestResultClosure`闭包 ( `Result<URLRequest, MoyaError> -> Void`的简写) 。
在这儿，您要做OAuth签名或者别的什么。由于您可以异步调用闭包，您可以使用任何您喜欢的权限认证库，如 ([example](https://github.com/rheinfabrik/Heimdallr.swift))。
//不修改请求，而是简单地将其记录下来。

```swift
let requestClosure = { (endpoint: Endpoint<GitHub>, done: MoyaProvider.RequestResultClosure) in
    do {
        var request = try endpoint.urlRequest()
        // Modify the request however you like.
        done(.success(request))
    } catch {
        done(.failure(MoyaError.underlying(error)))
    }

}
let provider = MoyaProvider<GitHub>(requestClosure: requestClosure)
```

`requestClosure`用来修改`URLRequest`的指定属性或者提供直到创建request才知道的信息（比如，cookie设置）给request是非常有用的。注意上面提到的`endpointClosure` 不是为了这个目的，也不是任何特定请求的应用级映射。

这个闭包参数实际在编辑请求对象时是非常有用的。
`URLRequest` 有很多你可以自定义的属性。比方，你想禁用所有请求的cookie:

```swift
{ (endpoint: Endpoint<ArtsyAPI>, done: MoyaProvider.RequestResultClosure) in
    do {
        var request: URLRequest = try endpoint.urlRequest()
        request.httpShouldHandleCookies = false
        done(.success(request))
    } catch {
        done(.failure(MoyaError.underlying(error)))
    }
}
```

您也可以在此完成网络请求的日志输出，因为这个闭包在request发送到网络之前每次都会被调用。
