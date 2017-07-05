# ReactiveSwift examples

ReactiveSwift extension to Moya is added via `reactive` property of `MoyaProvider`. As in normal setup,
we just need to create a provider first:

```swift
let provider = MoyaProvider<GitHub>()
```

And after that you're off to the races:

```swift
provider.reactive.request(.zen).start { event in
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
