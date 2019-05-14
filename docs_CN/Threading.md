# 线程

默认,您所有的请求将会被`Alamofire`放入background线程中, 响应将会在主线程中调用。如果您希望您的响应在不同的线程中调用 , 您可以用一个指定的 `callbackQueue`来初始化您的provider:

```swift
provider = MoyaProvider<GitHub>(callbackQueue: DispatchQueue.global(qos: .utility))
provider.request(.userProfile("ashfurrow")) {
    /* this is called on a utility thread */
}
```

使用 `RxSwift` 或者 `ReactiveSwift` 您可以使用 `observeOn(_:)` 或者 `observe(on:)` 来实现类似的的行为:

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
