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
provider.request(.Zen) { (data, statusCode, response, error) in
    if let data = data {
        // do something with the data
    }
}
```

That's it! The `request()` method returns a `Cancellable`, which has
only one public function, `cancel()`, which you can use to cancel the
request. 

Remember, *where* you put your target and the provider, are completely up 
to you. You can check out [Artsy's implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/ArtsyAPI.swift)
for an example. 

Advanced Use
------------

The first (optional) parameter for the `MoyaProvider` initializer is an 
endpoints closure, which is responsible for mapping a value of your enum to a 
concrete `Endpoint` instance. Let's take a look at what one might look like. 

```swift
let endpointsClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
    return Endpoint(URL: url!, sampleResponse: .Success(200, {target.sampleData}), method: target.method, parameters: target.parameters)
}
let provider = MoyaProvider(endpointsClosure: endpointsClosure)
```

Notice that we don't have to specify the generic type in the `MoyaProvider` 
initializer anymore, since Swift will infer it from the type of our
`endpointsClosure`. Neat!

This `endpointsClosure` is about as simple as you can get. Check out the
[Endpoints](Endpoints.md) documentation for more on _why_ you might want
to do this.

The next optional initializer parameter is `endpointResolver`, which resolves
an `Endpoint` to an actual `NSURLRequest`. Again, check out the [Endpoints](Endpoints.md) 
documentation for how and why you'd do this. 

The third optional parameter, `stubResponses`, is very straightforward: 
should the provider access the API or should it return the stubbed data? 

Another option is to provide a `stubBehavior` of either `.Immediate` (the
default) or `.Delayed(seconds)`, where you can delay every stubbed request 
by a certain number of seconds. For example, `.Delayed(0.2)` would delay
every stubbed request. This can be good for simulating network delays in
unit tests. Don't worry – Moya doesn't delay actual requests!

Finally, there's the `networkActivityClosure` parameter. This is a closure
that you can provide to be notified whenever a network request begins or
ends. This is useful for working with the [network activitiy indicator](https://github.com/thoughtbot/BOTNetworkActivityIndicator).
Note that signature of this closure is `(change: NetworkActivityChangeType) -> ()`, 
so you will only be notified when a request has `.Began` or `.Ended` – 
you aren't provided any other details about the request itself. 
