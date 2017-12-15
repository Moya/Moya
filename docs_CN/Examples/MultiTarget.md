# 高级用法 - 为多个target在同一个`Provider`中使用而采用 `MultiTarget` .

当你有很多endpoints你可能以一个非常长的provider和在上百个case里多次切换而告终。你当然可以把这些逻辑分割到多个target中，但是你同时不得不使用多个provider。这会让你的app逻辑变复杂，并且如果你希望为它们配置相同的插件/闭包，你需要花费额外的功夫来管理它们。为了解决这个麻烦，我们可以使用内置的`MultiTarget`枚举类型，它是相当的易用。

首先, 我们需要定义一个使 multiple target的provider:
```swift
let provider = MoyaProvider<MultiTarget>()
```

然后, 当你想启动请求的时候, 你需要替换
```swift
provider.request(.zen) { result in
    // do something with `result`
}
```

为

```swift
provider.request(MultiTarget(GitHub.zen)) { result in
    // do something with `result`
}
```

到此配置结束! 在您的app中采用它是相当的简单 而且如果您有很多想分割的
endpoints - 这是一个相当完美的解决方法. 如果你想看到这个API的作用, 查看我们的
[Demo](https://github.com/Moya/Moya/tree/master/Demo) 项目, 它里面有两个
target: 一个是 `Demo`, 它使用的Moya的基础版； 另一个是`DemoMultiTarget`,它使用`MultiTarget`的修改版本 。

## 在多目标中使用 `关联类型`

使用Moya能让您在调用网络请求时静态地验证参数。您可能想扩展Moya的 `TargetType` 并验证您的自定义类型。一种用例就是让请求方法返回基于请求的不同来序列化模型，而不是使用默认的`MoyaResponse`来返回。这可以通过在`TargetType`中添加 `associatedtype`来解决

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

由于 `associatedtype`, `MultiTarget` 不能被当做 `DecodableTargetType`.
但是, 我们可以使用 `MultiMoyaProvider` 变体. 它不需要泛型参数. 所以, 任何遵循`TargetType`的实例对象都可以调用这个请求. 使用 `MultiMoyaProvider` 允许你编写可以使用`associatedtype`的请求包装器.

比如, 我们可以创建一个返回`ResultType`的 `requestDecoded`方法 来替换 `MoyaResponse` 

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

其美妙之处在于，回调中的输入类型是由已传入的目标隐式地确定的.

您可以传入任何 `DecodableTargetType` 类型来启动一个请求

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

当使用 `associatedtype`, 您将需要为不同的类型定义不同的target 。 比如, 假设我们另外一个target叫 `SessionApi`

```swift
struct SessionApi: DecodableTargetType {
    typealias ResultType = SessionModel
}
```

它定义了一个不同的 `ResultType`. 我们可以使用相同的 `MultiMoyaProvider`
实例对象

```swift
provider.requestDecoded(SessionApi.get) { result in
    switch result {
    case .success(let session):
        // type of `user` is implicitly `SessionModel` here
    }
}
```
