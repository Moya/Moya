# Threading

By default, all of your requests will be put onto a background thread by `Alamofire`, and the 
response will be called on the main thread. If you want your response called on a different thread, you can initialize your `Provider` with a specified `callbackQueue`:
```swift
provider = MoyaProvider<GitHub>(callbackQueue: DispatchQueue.global(.utility))
provider.request(.userProfile("ashfurrow")) {
    /* this is called on a utility thread */
}
```

Using `RxSwift` & `ReactiveSwift` you can achieve similar behavior using `observeOn(_:)` & `observe(on:)` operators:

## RxSwift
```swift
provider = MoyaProvider<GitHub>()
provider.rx.request(.userProfile("ashfurrow"))
  .map { /* this is called on the current thread */ }
  .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
  .map { /* this is called on a utility thread */ }
```

## ReactiveSwift
```swift
provider = MoyaProvider<GitHub>()
provider.reactive.request(.userProfile("ashfurrow"))
  .map { /* this is called on the current thread */ }
  .observe(on: QueueScheduler(qos: .utility))
  .map { /* this is called on a utility thread */ }
```