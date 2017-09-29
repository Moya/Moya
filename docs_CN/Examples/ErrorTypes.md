# 处理不同的错误类型

如果出现错误，您可能需要处理它:

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

或者 RxSwift 的方式:

```swift
.do(onError: { error in
    // Handle error here
})
```

您可以使用 `switch`  `cases` 的方式来处理 `MoyaError`.在 `.underlying` 错误中您也可以获取原始的`Error` 和它的属性。 例如. `code` 可被用来推断 `URLError` 类型，比如 `NSURLErrorTimedOut` 和 `NSURLErrorNotConnectedToInternet`

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
case .underlying(let nsError as NSError, let response):
    // now can access NSError error.code or whatever
    // e.g. NSURLErrorTimedOut or NSURLErrorNotConnectedToInternet
    print(nsError.code)
    print(nsError.domain)
    print(response)
case .underlying(let error, let response):
    print(error)
    print(response)
case .requestMapping:
    print("nil")
}
```
