# Wrapping the **request -> result** cycle into own adapter

Moving towards a real-world example, you might want to wrap the **request ->
result** cycle in your own network adapter, to make it a little easier to
convert successful responses, show error messages and re-attempt after network
failures.

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
