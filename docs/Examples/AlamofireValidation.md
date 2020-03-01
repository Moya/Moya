# Alamofire automatic validation
Sometimes, you will want to use [Alamofire automatic validation](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#automatic-validation) for some requests.
When a request is configured with Alamofire validation, Moya will internally call Alamofire's  `validate()` method on the concerned `DataRequest`.

```swift
// MARK: - TargetType Protocol Implementation
extension MyService: TargetType {
    var baseURL: URL { URL(string: "https://api.myservice.com")! }
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
    
    // Validate setup is not required; defaults to `.none`
    // for all requests unless specified otherwise.
    var validationType: ValidationType {
        switch self {
        case .zen, .showUser, .showAccounts:
            return .successCodes
        case .createUser(let firstName, let lastName):
            return .none
        }
    }
}
```
Moya allows you to configure the Alamofire validation behavior through the `ValidationType` enum.
 
You can choose from four cases:
- `.none` which does not perform any validation.
- `.successCodes` which validates requests with status codes 200 - 299.
- `.successAndRedirectCodes` which validates requests with status codes 200 - 399.
- `.customCodes([Int])` which only validates the given status codes.

The default validation type for all requests is `ValidationType.none`.

Alamofire automatic validation can be useful, for example if you want to use the [Alamofire's `RequestRetrier` and `RequestAdapter`](https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#requestretrier), for an OAuth 2 ready Moya Client.

Also, if validation fails, you can get the response from the returned `MoyaError`.

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
