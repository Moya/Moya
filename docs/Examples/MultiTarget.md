Advanced usage - use `MultiTarget` for multiple targets using the same `Provider`.
===========

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
[Demo](https://github.com/Moya/Moya/tree/master/Demo) project, which has 2
targets: one of them is `Demo`, which uses the basic form of Moya, and the
second one is `DemoMultiTarget`, which uses the modified version with usage of
`MultiTarget`.
