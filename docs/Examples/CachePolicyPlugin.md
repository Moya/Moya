# Creating a Cache Policy Plugin

Cache Policies are the rules of how a URL load should be loaded. These rules are determined by the client cache requirements, the server's content expiration requirements, and the server's revalidation requirements.

Moya automatically handles the policies on client's side based on server response policies. There are many times that we want to manually handle the client's side policies either in all our request or on specific targets.

## Plugin Creation

Let's define a `CachePolicyGettableType` protocol to implement in our Targets:

```swift
protocol CachePolicyGettableType {
    var cachePolicy: URLRequest.CachePolicy? { get }
}
```

Let's define our plugin:

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

## Plugin Implementation
We need to add the `CachePolicyPlugin` to our `MoyaProvider`:

```swift
let provider = MoyaProvider<RequestTarget>(plugins: [CachePolicyPlugin()])
```

Also, our targets need to conform to our `CachePolicyGettableType` protocol:

```swift
extension RequestTarget: CachePolicyGettableType {
    var cachePolicy: URLRequest.CachePolicy? {
        .reloadIgnoringLocalCacheData
    }
}
```

## Using MultiTargets
It's important to keep in mind that if we are using `MultiTarget` in our Moya Provider to use any target, we need to extend `MultiTarget` for it to conform our `CachePolicyGettableType`:

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

This example is based on [Frederick Pietschmann](https://github.com/fredpi) `CachePolicyPlugin` proposal in the [Issue #1679](https://github.com/Moya/Moya/issues/1679)
