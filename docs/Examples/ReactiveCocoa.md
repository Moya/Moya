ReactiveCocoa examples
======================

A `ReactiveCocoaMoyaProvider` can be created much like a
[`MoyaProvider`](Providers.md) and can be used as follows:

```swift
let GitHubProvider = ReactiveCocoaMoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
provider.request(.Zen).start { (event) -> Void in
    switch event {
    case .Next(let response):
        // do something with the data
    case .Failed(let error):
        // handle the error
    default:
        break
    }
}
```
