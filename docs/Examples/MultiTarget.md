# Advanced usage - use `MultiTarget` for multiple targets using the same `Provider`.

When you have many endpoints you may end up with really long provider and
multiple switches on hundreds of cases. You could split the logic into multiple
targets but you would have to use multiple providers as well. This may
complicate your app logic and if you want to use the same plugins/closures for
each of them, it would require some work to maintain it. Instead, we can
use `MultiTarget` enum that's built-in and really easy to use.

First, we have to define provider that will take multiple targets:
```swift
let provider = MoyaProvider<MultiTarget>()
```

Then, when you want to start the request, you need to replace
```swift
provider.request(.zen) { result in
    // do something with `result`
}
```

to

```swift
provider.request(MultiTarget(GitHub.zen)) { result in
    // do something with `result`
}
```

and that's it! Really simple to introduce it in your app and if you have many
endpoints that you want to split - this is the perfect solution for you. If you
want to see this API in action, check out our
[Multi-Target sample projects](https://github.com/Moya/Moya#sample-project), 
which uses the modified version with usage of `MultiTarget`.

## Multiple targets when using `associatedtype`

Using Moya enables you to statically verify the arguments when invoking a
network request. You might want to extend Moya's `TargetType` to verify your
custom types. One use case is to have the `request` method return deserialized
models which vary based on request, instead of `MoyaResponse`. This can be
achieved by adding an `associatedtype` to `TargetType`

```swift
protocol DecodableTargetType: Moya.TargetType {
    associatedType ResultType: SomeJSONDecodableProtocolConformance
}

enum UserApi: DecodableTargetType {
    case get(id: Int)
    case update(id: Int, name: String)
    ...

    var baseURL: URL { ... }
    var path: String { switch self ... }
    var method: Moya.Method { ... }

    typealias ResultType = UserModel
}
```

Because of `associatedtype`, `MultiTarget` cannot be used with `DecodableTargetType`.
Instead, we can use the `MultiMoyaProvider` variant. It does not require a
generic argument. 

```swift
final class MultiMoyaProvider: MoyaProvider<MultiTarget> {

    typealias Target = MultiTarget

    override init(endpointClosure: @escaping MoyaProvider<Target>.EndpointClosure, requestClosure: @escaping MoyaProvider<Target>.RequestClosure, stubClosure: @escaping MoyaProvider<Target>.StubClosure, callbackQueue: DispatchQueue?, manager: Manager, plugins: [PluginType], trackInflights: Bool) {

        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)

    }
}
```

Thus, requests can be invoked with any instance that
conforms to `TargetType`. Using `MultiMoyaProvider` allows you to write
request wrappers which can make use of your `associatedtype`s.

For example, we can build a `requestDecoded` method that returns `ResultType`
instead of `MoyaResponse` as

```swift
extension MultiMoyaProvider {
    func requestDecoded<T: DecodableTargetType>(_ target: T, completion: @escaping (_ result: Result<[T.ResultType], Moya.Error>) -> ()) -> Cancellable {
        return request(target) { result in
            switch result {
            case .success(let response):
                if let parsed = T.ResultType.parse(try! response.mapJSON()) {
                    completion(.success(parsed))
                } else {
                    completion(.failure(.jsonMapping(response)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

The beauty of this is that the type of input in the callback is implicitly
determined from the target passed.

You can pass any `DecodableTargetType` to start a request

```swift
let provider = MultiMoyaProvider()
provider.requestDecoded(UserApi.get(id: 1)) { result in
    switch result {
    case .success(let user):
      // type of `user` is implicitly `UserModel`. Using any other type results
      // in compile error
      print(user.name)
    }
}
```

When using `associatedtype`, you will have to define different targets to work
with different types. For example, lets say we have another target `SessionApi`

```swift
struct SessionApi: DecodableTargetType {
    typealias ResultType = SessionModel
}
```

which has a different `ResultType`. We can use the same `MultiMoyaProvider`
instance

```swift
provider.requestDecoded(SessionApi.get) { result in
    switch result {
    case .success(let session):
        // type of `session` is implicitly `SessionModel` here
    }
}
```
