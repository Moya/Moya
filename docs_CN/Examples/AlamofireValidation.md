# Alamofire 自动验证

有时候, 您希望为某些请求使用 [Alamofire自动化验证](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#automatic-validation) .
当你对请求配置了Alamofire 验证的时候, Moya会在相关联的`DataRequest`上，内部调用Alamofire的 `validate()` 方法。

```swift
// MARK: - TargetType Protocol Implementation
extension MyService: TargetType {
    var baseURL: URL { return URL(string: "https://api.myservice.com")! }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .showUser(let id):
            return "/users/\(id)"
        case .createUser:
            return "/users"
        case .showAccounts:
              return "/accounts"
        }
    }
    
    // Other needed configurations
    // ...
    
    // Validate setup is not required; defaults to `false`
    // for all requests unless specified otherwise.
    var validate: Bool {
        switch self {
        case .zen, .showUser, .showAccounts:
            return true
        case .createUser(let firstName, let lastName):
            return false
        }
    }
}
```
Moya允许你通过`ValidationType`枚举配置Alamofire验证功能。

你可以使用以下四个枚举项:
- `.none` 不会进行任何验证
- `.successCodes` 会对状态码 200 - 299 的请求进行验证.
- `.successAndRedirectCodes` 会对状态码 200 - 399 的请求进行验证.
- `.customCodes([Int])` 只会对配置的状态码相匹配的请求进行验证.

所有请求的默认配置都是`ValidationType.none`。

如果你想在一个支持OAuth 2的Moya客户端中使用 [Alamofire的 `RequestRetrier` 和 `RequestAdapter`](https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#requestretrier)，Alamofire自动化验证会发挥非常大的作用。

同样地, 如果验证失败, 你会从返回的`MoyaError`中获取到一个响应。

```swift
provider.request(target) { result in
    ...
    if case let .failure(error) = result {
        response = error.response
        // Do something with the response
    }
    ...
}
```
