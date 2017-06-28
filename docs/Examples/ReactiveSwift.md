# ReactiveSwift examples

A `ReactiveSwift`-based `MoyaProvider` can be created much like a
[`MoyaProvider`](../Providers.md) and can be used as follows:

```swift
let provider = MoyaProvider<GitHub>().reactive
```

After that simple setup, you're off to the races:

```swift
provider.request(.zen).start { event in
    switch event {
    case .next(let response):
        // do something with the data
    case .failed(let error):
        // handle the error
    default:
        break
    }
}
```
