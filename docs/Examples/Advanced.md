Advanced
=======

#### Alamofire automatic validation
Sometimes, you will want to use [Alamofire automatic validation](https://github.com/Alamofire/Alamofire#automatic-validation) for some requests.
When a request is configured with Alamofire validation, Moya will internally call Alamofire's  `validate()` method on the concerned `DataRequest`.

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
Alamofire automatic validation can be useful, for example if you want to use the [Alamofire's `RequestRetrier` and `RequestAdapter`](https://github.com/Alamofire/Alamofire#requestretrier), for an oAuth 2 ready Moya Client.