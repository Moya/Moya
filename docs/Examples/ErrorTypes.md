Handling different error types
==============================

In case of an error you may need to handle it:

```swift
provider.request(target) { result in
    switch result {
    case let .success(response):
        // Do sg on success
    case let .failure(error):
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

You can do that by a `switch` on different `cases` of `MoyaError`. In case of an `.Underlying` error you can also get the original `NSError` and its properties, e.g. `code` to be informed about `NSURLError` types like `NSURLErrorTimedOut` or `NSURLErrorNotConnectedToInternet`

```swift
switch error {
case .data(let response):
    print(response)
case .imageMapping(let response):
    print(response)
case .jsonMapping(let response):
    print(response)
case .statusCode(let response):
    print(response)
case .stringMapping(let response):
    print(response)
case .underlying(let nsError):
    // now can access NSError error.code or whatever
    // e.g. NSURLErrorTimedOut or NSURLErrorNotConnectedToInternet
    print(nsError.code)
    print(nsError.domain)
}
```
