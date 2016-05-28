Subclassing Provider and refreshing session automatically
=========================================================

Based on [Artsy's implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/Networking.swift).

Used RxSwift.

```swift
class OnlineProvider: RxMoyaProvider<MyService> {
    
    // First of all, we need to override designated initializer
    override init(endpointClosure: MoyaProvider<MyService>.EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: MoyaProvider<MyService>.RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: MoyaProvider<MyService>.StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [PluginType] = []) {
            
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }
    
    // Request to fetch and store new XApp token if the current token is missing or expired.
    func XAppTokenRequest() -> Observable<String?> {
        
        var appToken = UserInfo.sharedInstance.accessToken
        
        // If we have a valid token, just return it
        if appToken.isValidAndNotExpired {
            return Observable.just(appToken.token)
        }
        
        // Do not attempt to refresh a session if we don't have valid credentials
        guard let userId = UserInfo.sharedInstance.userId, refreshToken = UserInfo.sharedInstance.accessToken.refreshToken else {
            return Observable.just(nil)
        }
        
        // Create actual refresh request
        let newTokenRequest = super.request(MyService.RefreshSession(userId: userId, resfreshToken: refreshToken))
            .filterSuccessfulStatusCodes()
            .mapJSON()
            .map { element -> (token: String?, refreshToken: String?, expiryTime: Double?) in
                guard let dictionary = element as? NSDictionary else { return (token: nil, refreshToken: nil, expiryTime: nil) }
                
                return (token: dictionary["auth_token"] as? String, refreshToken: dictionary["refresh_token"] as? String, expiryTime: dictionary["session_time_valid"] as? Double)
            }
            .doOn { event in
                guard case Event.Next(let element) = event else { return }
                
                UserInfo.sharedInstance.accessToken.token = element.0
                UserInfo.sharedInstance.accessToken.refreshToken = element.1
                UserInfo.sharedInstance.accessToken.setExpirySecondsLeft(element.2)
            }
            .map { (token, refreshToken, expiry) -> String? in
                return token
            }
            .catchError { e -> Observable<String?> in
                guard let error = e as? Moya.Error else { throw e }
                guard case .StatusCode(let response) = error else { throw e }
                
                // If we have 401 error - delete all credentials and handle logout
                if response.statusCode == 401 {
                    UserInfo.sharedInstance.invalidate()
                    Router.sharedInstance.popToLoginScreen()
                }
                throw error
            }
        
        return newTokenRequest
    }
    
    // Override request to inject XAppTokenRequest if needed
    override func request(token: MyService) -> Observable<Moya.Response> {
        let actualRequest = super.request(token)
        
        return self.XAppTokenRequest().flatMap { _ in
            actualRequest
        }
    }
}
```

Create custom provider the same way as usual:

```swift
let MyServiceProvider = OnlineProvider()
```

Also you can pass parameters there:

```swift
let MyServiceProvider = OnlineProvider(endpointClosure: endpointClosure, plugins: [NetworkLogger()])
```
