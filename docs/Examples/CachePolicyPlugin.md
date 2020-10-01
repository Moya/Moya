＃创建一个缓存策略插件

缓存策略是应如何加载URL加载的规则。这些规则由客户端缓存要求，服务器的内容到期要求和服务器的重新验证要求确定。

Moya根据服务器响应策略自动处理客户端的策略。很多时候，我们希望在所有请求中或在特定目标上手动处理客户端的边策略。

##插件创建

让我们定义一个 `CachePolicyGettableType` 在我们的目标中实施的协议：

```swift
protocol CachePolicyGettableType {
    var cachePolicy: URLRequest.CachePolicy? { get }
}
```

让我们定义我们的插件：

```swift
final class CachePolicyPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let policyGettable = target as? CachePolicyGettableType, let policy = policyGettable.policy else {
            return request
        }

        var mutableRequest = request
        mutableRequest.cachePolicy = policy

        return mutableRequest
    }
}
```

##插件实现
我们需要添加 `CachePolicyPlugin` 给我们 `MoyaProvider`:

```swift
let provider = MoyaProvider<RequestTarget>(plugins: [CachePolicyPlugin()])
```

另外，我们的目标必须符合我们的 `CachePolicyGettableType` 协议：

```swift
extension RequestTarget: CachePolicyGettableType {
    var cachePolicy: URLRequest.CachePolicy? {
        .reloadIgnoringLocalCacheData
    }
}
```

##使用多目标

重要的是要记住，如果我们使用 `MultiTarget` 在Moya提供商中使用任何目标，我们需要扩展 `MultiTarget` 让它符合我们的 `CachePolicyGettableType`:

```swift
extension MultiTarget: CachePolicyGettableType {
    public var policy: URLRequest.CachePolicy? {
        // Validates if target conforms CachePolicyGettableType protocol
        guard let policyTarget = target as? CachePolicyGettableType else {
            return nil
        }
        
        return policyTarget.policy
    }
}
```

---

这个例子是基于 [Frederick Pietschmann](https://github.com/fredpi) `CachePolicyPlugin` 提案 [Issue #1679](https://github.com/Moya/Moya/issues/1679)
