# ReactiveSwift

Moya在`MoyaProvider`中提供了一个可选的`ReactiveSwift` 实现，它可以做些有趣的事情。我们使用`SignalProducer`而不使用`request()`及请求完成时的回调闭包。


使用reactive扩展您不需要任何额外的设置。只使用您的 `MoyaProvider`实例对象 。

```swift
let provider = MoyaProvider<GitHub>()
```

简单设置之后, 您就可以使用了：

```swift
provider.reactive.request(.zen).start { event in
    switch event {
    case let .value(response):
        // do something with the data
    case let .failed(error):
        // handle the error
    default:
        break
    }
}
```

您也可以使用 `requestWithProgress` 来追踪您请求的进度 :

```swift
provider.reactive.requestWithProgress(.zen).start { event in
    switch event {
    case .value(let progressResponse):
        if let response = progressResponse.response {
            // do something with response
        } else {
            print("Progress: \(progressResponse.progress)")
        }
    case .failed(let error):
        // handle the error
    default:
        break
    }
}
```

请务必记住直到signal被订阅之后网络请求才会开始。signal订阅者在网络请求完成前被销毁了，那么这个请求将被取消 。

如果请求正常完成，两件事件将会发生：

1. 这个信号将发送一个值，即一个 `Moya.Response` 实例对象.
2. 信号结束.

如果这个请求产生了一个错误 (通常一个 URLSession 错误),
然后它将发送一个错误. 这个错误的 `code` 就是失败请求的状态码, if any, and the response data, if any.

`Moya.Response` 类包含一个 `statusCode`, 一个 `data`,
和 一个( 可选的) `HTTPURLResponse`. 您可以在 `startWithNext` 或 `map` 回调中随意使用这些值.

为了让事情更加简便, Moya 为`SignalProducer`提供一些扩展来更容易的处理`Moya.Responses`。


- `filter(statusCodes:)` 指定一范围的状态码。如果响应的状态代码不是这个范围内,会产生一个错误。
- `filter(statusCode:)` 查看指定的一个状态码，如果没找到会产生一个错误。
- `filterSuccessfulStatusCodes()` 过滤 200-范围内的状态码.
- `filterSuccessfulStatusAndRedirectCodes()` 过滤 200-300 范围内的状态码。
- `mapImage()` 尝试把响应数据转化为 `UIImage` 实例
  如果不成功将产生一个错误。
- `mapJSON()` 尝试把响应数据映射成一个JSON对象，如果不成功将产生一个错误。
- `mapString()` 把响应数据转化成一个字符串，如果不成功将产生一个错误。
- `mapString(atKeyPath:)` 尝试把响应数据的key Path 映射成一个字符串，如果不成功将产生一个错误。


在错误的情况下, 错误的 `domain`是 `MoyaErrorDomain`。code
的值是`MoyaErrorCode`的其中一个的`rawValue`值。 只要有可能，会提供underlying错误并且原始响应数据会被包含在`NSError`的字典类型的`userInfo`的data中