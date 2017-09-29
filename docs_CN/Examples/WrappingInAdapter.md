# 把 **request -> result**流程，包装到自己的适配器中

转向一个现实的例子, 你可能想把 **request ->
result** 流程包装到你自己的网络适配器中, 这样可以让它更容易的转换成功的响应、展示错误的信息并在网络故障后再次尝试。

```swift
struct Network {
    static let provider = MoyaProvider<MyService>(endpointClosure: endpointClosure)

    static func request(
        target: MyService,
        success successCallback: (JSON) -> Void,
        error errorCallback: (statusCode: Int) -> Void,
        failure failureCallback: (MoyaError) -> Void
    ) {
        provider.request(target) { result in
            switch result {
            case let .success(response):
                do {
                    try response.filterSuccessfulStatusCodes()
                    let json = try JSON(response.mapJSON())
                    successCallback(json)
                }
                catch error {
                    errorCallback(error)
                }
            case let .failure(error):
                if target.shouldRetry {
                    retryWhenReachable(target, successCallback, errorCallback, failureCallback)
                }
                else {
                    failureCallback(error)
                }
            }
        }
    }
}

// usage:
Network.request(.zen, success: { zen in
    showMessage(zen)
}, error: { err in
    showError(err)
}, failure: { _ in
    // oh well, no network apparently
})
```
