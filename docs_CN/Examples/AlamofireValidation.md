# Alamofire 自动验证

有时候, 您希望为某些请求使用 [Alamofire automatic validation](https://github.com/Alamofire/Alamofire#automatic-validation) .
当请求被配置了Alamofire 验证, Moya会在相关联的`DataRequest`上，内部调用Alamofire的 `validate()` 方法。


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
Alamofire 非常有用, 例如，如果你想使用 [Alamofire's `RequestRetrier` 和 `RequestAdapter`](https://github.com/Alamofire/Alamofire#requestretrier)——为OAuth2 准备的Moya客户端.

同样, 如果验证失败, 你会从返回的`MoyaError`中获取一个响应。

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
