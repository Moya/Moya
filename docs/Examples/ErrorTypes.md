Handling different error types
==============================

In case of an error you may need to handle it:

```swift
provider.request(target) { result in
    switch result {
    case let .Success(response):
        // Do sg on success
    case let .Failure(error):
        // Handle error here
    }
}
```

Or RxSwift way:

```swift
.doOnError { error in
    // Handle error here
}
```

You can do that by a `switch` on different `cases` of `Moya.Error`. In case of an `.Underlying` error you can also get the original `NSError` and its properties, e.g. `code` to be informed about `NSURLError` types like `NSURLErrorTimedOut` or `NSURLErrorNotConnectedToInternet`

```swift
switch error {
case .Data(let response):
    print(response)
case .ImageMapping(let response):
    print(response)
case .JSONMapping(let response):
    print(response)
case .StatusCode(let response):
    print(response)
case .StringMapping(let response):
    print(response)
case .Underlying(let nsError):
    // now can access NSError error.code or whatever
    // e.g. NSURLErrorTimedOut or NSURLErrorNotConnectedToInternet
    print(nsError.code)
    print(nsError.domain)
}
```
