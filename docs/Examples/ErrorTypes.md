# Handling different error types

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
.do(onError: { error in
    // Handle error here
})
```

You can do that by a `switch` on different `cases` of `MoyaError`. In case of an `.underlying` error you can also get the original `Error` and its properties. e.g. `code` to be informed about `URLError` types like `NSURLErrorTimedOut` or `NSURLErrorNotConnectedToInternet`

```swift
switch moyaError {
case .imageMapping(let response):
    print(response)
case .jsonMapping(let response):
    print(response)
case .statusCode(let response):
    print(response)
case .stringMapping(let response):
    print(response)
case .objectMapping(let error, let response):
    // error is DecodingError
    print(response)
case .encodableMapping(let error):
    print(error)
case .underlying(let nsError as NSError, let response):
    // now can access NSError error.code or whatever
    // e.g. NSURLErrorTimedOut or NSURLErrorNotConnectedToInternet
    print(nsError.code)
    print(nsError.domain)
    print(response)
case .underlying(let error, let response):
    print(error)
    print(response)
case .requestMapping(let url):
    print(url)
case .parameterEncoding(let error):
    print(error)
}
```
