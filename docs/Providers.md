# Providers

When using Moya, you make all API requests through a `MoyaProvider` instance,
passing in a value of your enum that specifies which endpoint you want to call.
After setting up your [Endpoint](Endpoints.md), you're basically all set for
basic usage:

```swift
let provider = MoyaProvider<MyService>()
```

After that simple setup, you're off to the races:

```swift
provider.request(.zen) { result in
    // `result` is either .success(response) or .failure(error)
}
```

That's it! The `request()` method returns a `Cancellable`, which has
only one public function, `cancel()`, which you can use to cancel the
request. See [Examples](Examples) for more information about the `Result`
type.

Remember, *where* you put your target and the provider, are completely up
to you. You can check out [Artsy's implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/ArtsyAPI.swift)
for an example.

Always remember to retain your providers, as they will get deallocated if you fail to do so. Deallocation will return a `-999 "canceled"` error on response.

The same reminder applies also to Moya Reactive implementations, but you will not receive any response because the whole Observable will be disposed, releasing any subscription that you may have configured.

## Advanced Usage

To explain all configuration options you have with a `MoyaProvider` we will cover each parameter one by one in the following sections.

### endpointClosure:

The first (optional) parameter for the `MoyaProvider` initializer is an
endpoints closure, which is responsible for mapping a value of your enum to a
concrete `Endpoint` instance. Let's take a look at what one might look like.

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint in
    let url = URL(target: target).absoluteString
    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
}
let provider = MoyaProvider(endpointClosure: endpointClosure)
```

Notice that we don't have to specify the generic type in the `MoyaProvider`
initializer anymore, since Swift will infer it from the type of our
`endpointClosure`. Neat!

You may also notice the `URL(target:)` initializer, Moya provides a convenient extension to create a `URL` from any `TargetType`.

This `endpointClosure` is about as simple as you can get. It's actually the
default implementation, too, stored in `MoyaProvider.defaultEndpointMapping`.
Check out the [Endpoints](Endpoints.md) documentation for more on _why_ you
might want to customize this.

### requestClosure:

The next optional initializer parameter is `requestClosure`, which resolves
an `Endpoint` to an actual `URLRequest`. Again, check out the [Endpoints](Endpoints.md)
documentation for how and why you'd do this.

### stubClosure:

The next option is to provide a `stubClosure`. This returns one of either `.never` (the
default), `.immediate` or `.delayed(seconds)`, where you can delay the stubbed
request by a certain number of seconds. For example, `.delayed(0.2)` would delay
every stubbed request. This can be good for simulating network delays in unit tests.

What's nice is that if you need to stub some requests differently than others,
you can use your own closure.

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { target: MyTarget -> Moya.StubBehavior in
    switch target {
        /* Return something different based on the target. */
    }
})
```

But usually you want the same stubbing behavior for all your targets. There are
three class methods on `MoyaProvider` you can use instead.

```swift
MoyaProvider.neverStub
MoyaProvider.immediatelyStub
MoyaProvider.delayedStub(seconds)
```

So, in the above example, if you wanted immediate stubbing behavior for all
targets, either of the following would work.

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { (_: MyTarget) -> Moya.StubBehavior in return .immediate })
let provider = MoyaProvider<MyTarget>(stubClosure: MoyaProvider.immediatelyStub)
```

### session:

Next, there's the `session` parameter. By default you'll get a custom `Alamofire.Session` instance with basic configurations.

```swift
final class func defaultAlamofireSession() -> Session {
    let configuration = URLSessionConfiguration.default
    configuration.headers = .default
    
    return Session(configuration: configuration, startRequestsImmediately: false)
}
```

There is only one particular thing: since construct an `Alamofire.Request` in AF will fire the request immediately by default, even when "stubbing" the requests for unit testing. Therefore in Moya, `startRequestsImmediately` is set to `false` by default.

If you'd like to customize your own session, for example, to add SSL pinning, create one and pass it in,
all requests will route through the custom configured manager.

```swift
let serverTrustManager = ServerTrustManager(evaluators: ["example.com": PinnedCertificatesTrustEvaluator()])

let session = Session(
    configuration: configuration, 
    startRequestsImmediately: false, 
    serverTrustManager: serverTrustManager
)

let provider = MoyaProvider<MyTarget>(session: session)
```

### plugins:

You may also provide an array of `plugins` to the provider. These receive callbacks
before a request is sent and after a response is received. There are a few plugins
included already: one for network activity (`NetworkActivityPlugin`), one for logging
all network activity (`NetworkLoggerPlugin`), and another for [HTTP Authentication](Authentication.md).

For example you can enable the logger plugin by simply passing `[NetworkLoggerPlugin()]` alongside the `plugins` parameter of your `Endpoint`. Note that a plugin can also be configurable, for example the already included `NetworkActivityPlugin` requires a `networkActivityClosure` parameter. The configurable plugin implementation looks like this:

```swift
public final class NetworkActivityPlugin: PluginType {

    public typealias NetworkActivityClosure = (_ change: NetworkActivityChangeType, _ target: TargetType) -> Void
    let networkActivityClosure: NetworkActivityClosure

    public init(networkActivityClosure: @escaping NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public func willSend(_ request: RequestType, target: TargetType) {
        networkActivityClosure(.began, target)
    }

    /// Called by the provider as soon as a response arrives, even if the request is canceled.
    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        networkActivityClosure(.ended, target)
    }
}
```

The `networkActivityClosure` is a closure that you can provide to be notified whenever a network request begins or
ends. This is useful for working with the [network activity indicator](https://github.com/thoughtbot/BOTNetworkActivityIndicator).
Note that signature of this closure is `(_ change: NetworkActivityChangeType, _ target: TargetType) -> Void`,
so you will only be notified when a request has `.began`/`.ended` and for which `target` –
you aren't provided any other details about the request itself.

### trackInflights:

Finally, if you set `trackInflights` to `true`, the provider will prevent duplicate requests by reusing the pending request.
