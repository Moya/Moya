# Composing Provider

You should compose provider when you need to add or customize the behavior from `MoyaProvider`.

You can use this to do HTTP requests only when your app has internet connection or to handle session refresh automatically and more!

Let's go through some code.

First we will create a provider to do HTTP request when the app is online, We are going to use RxSwift.

```swift
final class OnlineProvider<Target> where Target: Moya.TargetType {
    private let provider: MoyaProvider<Target>

    // Observable that emmits a boolean value to indicate if we are online or offline
    private let online: Observable<Bool>

    // initialize our custom provider with all default values from MoyaProvider
    // and the online observable
    init(endpointClosure: @escaping MoyaProvider<Target>.EndpointClosure = MoyaProvider.defaultEndpointMapping,
         requestClosure: @escaping MoyaProvider<Target>.RequestClosure = MoyaProvider.defaultRequestMapping,
         stubClosure: @escaping MoyaProvider<Target>.StubClosure = MoyaProvider.neverStub,
         manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
         plugins: [PluginType] = [],
         trackInflights: Bool = false,
         online: Observable<Bool>) {

             self.online = online
             self.provider = MoyaProvider(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)
         }
```

Now we need a method to perform the request

```swift
func request(_ token: Target) -> Single<Moya.Response> {
    let actualRequest = provider.rx.request(token)

    return online
        .ignore(value: false) // Wait until we are online
        .take(1) // Take 1 to make sure we only invoke the API once.
        .flatMap { _ in // Turn the online state into a network request
           return actualRequest
        }
}
```

And that's it! 

You can create and use the custom provider the same way as usual:

```swift
let myServiceProvider = OnlineProvider(online: onlineObservable)
myServiceProvider.request(MyAPI.users)
```

Also you can pass parameters there:

```swift
let myServiceProvider = OnlineProvider(endpointClosure: endpointClosure, plugins: [NetworkLogger()], online: onlineObservable)
myServiceProvider.request(MyAPI.users)
```

For a more detailed example, you can look at [Artsy's implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/Networking.swift).
