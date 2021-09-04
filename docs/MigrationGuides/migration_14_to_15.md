# Migration Guide from 14.x to 15.x

This project follows [Semantic Versioning](http://semver.org).

### AccessTokenPlugin migration
`AccessTokenPlugin` now uses `TargetType`, instead of `AuthorizationType`, in the closure to determine the token. This also supports `MultiTarget` out of the box, so if you were depending on the `authorizationType`, now you need to switch the logic to cover for `target` as well, e.g.:
```swift
let plugin = AccessTokenPlugin { authorizationType in
    guard authorizationType == .bearer else { return "" }

    return "token"
}
```
would need to update to something similar to:
```swift
let plugin = AccessTokenPlugin { target in
    guard let target = target as? AccessTokenAuthorizable, target.authorizationType == .bearer else { return "" }

    return "token"
}
```

### `Target.sampleData` updates
With this update, `sampleData` is by default not needed to implement anymore - we've added a default implementation `Data()` and we plan to investigate possible improvements to the stubbing system in the future.
