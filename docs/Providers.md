Providers
=========

When using Moya, you make all API requests through a `MoyaProvider` instance, 
passing in a value of your enum that specifies which endpoint you want to call. 
After setting up your [Endpoint](Endpoints.md), you're basically all set for
basic usage:

```swift
let GitHubProvider = MoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
provider.request(.Zen) { result in
    // `result` is either .Success(response) or .Failure(error)
}
```

That's it! The `request()` method returns a `Cancellable`, which has
only one public function, `cancel()`, which you can use to cancel the
request.  See [Examples](Examples.md) for more information about the `Result`
type.

Remember, *where* you put your target and the provider, are completely up 
to you. You can check out [Artsy's implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/ArtsyAPI.swift)
for an example. 

Advanced Use
------------

The first (optional) parameter for the `MoyaProvider` initializer is an 
endpoints closure, which is responsible for mapping a value of your enum to a 
concrete `Endpoint` instance. Let's take a look at what one might look like. 

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
    return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
}
let provider = MoyaProvider(endpointClosure: endpointClosure)
```

Notice that we don't have to specify the generic type in the `MoyaProvider` 
initializer anymore, since Swift will infer it from the type of our
`endpointClosure`. Neat!

This `endpointClosure` is about as simple as you can get. It's actually the 
default implementation, too, stored in `MoyaProvider.DefaultEndpointMapping`. 
Check out the [Endpoints](Endpoints.md) documentation for more on _why_ you 
might want to customize this.

The next optional initializer parameter is `requestClosure`, which resolves
an `Endpoint` to an actual `NSURLRequest`. Again, check out the [Endpoints](Endpoints.md) 
documentation for how and why you'd do this. 

The next option is to provide a `stubClosure`. This returns one of either `.Never` (the 
default), `.Immediate` or `.Delayed(seconds)`, where you can delay the stubbed 
request by a certain number of seconds. For example, `.Delayed(0.2)` would delay
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

But usually you want the same stubbing behaviour for all your targets. There are
three class methods on `MoyaProvider` you can use instead.

```swift
MoyaProvider.NeverStub
MoyaProvider.ImmediatelyStub
MoyaProvider.DelayedStub(seconds)
```

So, in the above example, if you wanted immediate stubbing behaviour for all 
targets, either of the following would work.

```swift
let provider = MoyaProvider<MyTarget>(stubClosure: { (_: MyTarget) -> Moya.StubBehavior in return .Immediate })
let provider = MoyaProvider<MyTarget>(stubBehavior: MoyaProvider.ImmediatelyStub)
```

Next, there's the `manager` parameter. By default you'll get a custom `Alamofire.Manager` instance with basic configurations.

```swift
public final class func DefaultAlamofireManager() -> Manager {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders

    let manager = Alamofire.Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}
```

There is only one particular thing: since construct an `Alamofire.Request` in AF will fire the request immediately by default, even when "stubbing" the requests for unit testing. Therefore in Moya, `startRequestsImmediately` is set to `false` by default.

If you'd like to customize your own manager, for example, to add SSL pinning, create one and pass it in,
all requests will route through the custom configured manager.

```swift
let policies: [String: ServerTrustPolicy] = [
    "example.com": .PinPublicKeys(
        publicKeys: ServerTrustPolicy.publicKeysInBundle(),
        validateCertificateChain: true,
        validateHost: true
    )
]

let manager = Manager(
    configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
    serverTrustPolicyManager: ServerTrustPolicyManager(policies: policies)
)

let provider = MoyaProvider<MyTarget>(manager: manager)
```

Finally, you may also provide an array of `plugins` to the provider. These receive callbacks
before a request is sent and after a response is received. There are a few plugins
included already: one for network activity (`NetworkActivityPlugin`), one for logging
all network activity (`NetworkLoggerPlugin`), and another for [HTTP Authentication](Authentication.md).

```
public final class NetworkActivityPlugin: PluginType {
    
    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()
    let networkActivityClosure: NetworkActivityClosure
    
    public init(networkActivityClosure: NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public func willSendRequest(request: RequestType, target: TargetType) {
        networkActivityClosure(change: .Began)
    }

    /// Called by the provider as soon as a response arrives
    public func didReceiveResponse(data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, target: TargetType) {
        networkActivityClosure(change: .Ended)
    }
}
```

For instance, if you want to add a `NetworkActivityPlugin`, it requires a `networkActivityClosure` parameter. 
This is a closure that you can provide to be notified whenever a network request begins or
ends. This is useful for working with the [network activitiy indicator](https://github.com/thoughtbot/BOTNetworkActivityIndicator).
Note that signature of this closure is `(change: NetworkActivityChangeType) -> ()`,
so you will only be notified when a request has `.Began` or `.Ended` –
you aren't provided any other details about the request itself.
