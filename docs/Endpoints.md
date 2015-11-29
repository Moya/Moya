Endpoints
=========

An endpoint is a semi-internal data structure that Moya uses to reason about 
the network request that will ultimately be made. An endpoint stores the 
following data:

- The URL.
- The HTTP method (GET, POST, etc).
- The request parameters.
- The parameter encoding (URL, JSON, custom, etc).
- The HTTP request header fields.
- The sample response (for unit testing).

[Providers](Providers.md) map [Targets](Targets.md) to Endpoints, then map
Endpoints to actual network requests. 

There are two ways that you interact with Endpoints. 

1. When creating a provider, you may specify a mapping from Target to Endpoint.
1. When creating a provider, you may specify a mapping from Endpoint to `NSURLRequest`. 

The first might resemble the following:

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
    return Endpoint(URL: url!, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
}
```

This is actually the default implementation Moya provides. If you need something 
custom, like if your API requires custom parameter mapping, or if you're 
creating a test provider that returns non-200 HTTP statuses in unit tests, this
is where you would do it. 

The second use is very uncommon. Moya tries to prevent you from having to worry
about low-level details. But it's there if you need it. Its use is covered 
further below.

Let's take a look at an example of the flexibility mapping from a Target to 
an Endpoint can provide. 

From Target to Endpoint 
-----------------------

By default, `Endpoint` instances use the `.URL` type parameter encoding. You
can specify how you'd like to encode parameters on a target-by-target basis in
the `endpointClosure` using the optional `parameterEncoding` parameter of the
`Endpoint` initializer in your `endpointClosure` when setting up the provider. 

There are four parameter encoding types: `.URL`, `.JSON`, `.PropertyList`, and
`.Custom`, which map directly to the corresponding types in Alamofire. These 
are also configured in the `endpointClosure` of the provider. Usually you just
want `.URL`, but you can use whichever you like. These are mapped directly to
the [Alamofire parameter encodings](https://github.com/Alamofire/Alamofire/blob/3d271dbbf12e104ab1373bff36c91c5ecbcc3890/Source/ParameterEncoding.swift#L47).

You can add parameters or HTTP header fields in this closure. For example, we 
may wish to set our application name in the HTTP header fields for server-side
analytics. 

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let endpoint: Endpoint<MyTarget> = Endpoint<MyTarget>(URL: url(target), sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
    return endpoint.endpointByAddingHTTPHeaderFields(["APP_NAME": "MY_AWESOME_APP"])
}
```

This also means that you can provide additional parameters to some or all of 
your endpoints. For example, say that there is an authentication token we need
for  all values of the hypothetical `MyTarget` target, with the exception of the 
target that actually does the authentication. We could construct an 
`endpointClosure` resembling the following. 

```swift
let endpointClosure = { (target: MyTarget) -> Endpoint<MyTarget> in
    let endpoint: Endpoint<MyTarget> = Endpoint<MyTarget>(URL: url(target), sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)

    // Sign all non-authenticating requests
    switch target {
    case .Authenticate:
        return endpoint
    default:
        return endpoint.endpointByAddingHTTPHeaderFields(["AUTHENTICATION_TOKEN": GlobalAppStorage.authToken])
    }
}
```

Awesome. 

Note that we can rely on the existing behaviour of Moya and extend – instead
of replace – it. The `endpointByAddingParameters` and `endpointByAddingHTTPHeaderFields`
functions allow you to rely on the existing Moya code and add your own custom
values. 

Sample responses are a requirement of the `TargetType` protocol. However, they
only specify the data returned. The Target-to-Endpoint mapping closure is where
you can specify more details, which is useful for unit testing. 

Sample responses have one of two values:

- `NetworkResponse`, with an `Int` status code and an `NSData` returned data.
- `NetworkError`, with an `ErrorType?` optional error type.

 
Request Mapping
---------------

As we mentioned earlier, the purpose of this library is not really to provide a
coding framework with which to access the network – that's Alamofire's job. 
Instead, Moya is about a way to frame your thoughts about network access and 
provide compile-time checking of well-defined network targets. You've already 
seen how to map targets into endpoints using the `endpointClosure` parameter
of the `MoyaProvider` initializer. That lets you create an `Endpoint` instance
that Moya will use to reason about the network API call. At some point, that
`Endpoint` must be resolved into an actual `NSURLRequest` to give to Alamofire. 
That's what the `requestClosure` parameter is for. 

The `requestClosure` is an optional, last-minute way to modify the request 
that hits the network. It has a default value of `MoyaProvider.DefaultRequestMapper`, 
which simply uses the `urlRequest` property of the `Endpoint` instance. 

This closure receives an `Endpoint` instance and is responsible for invoking a
its argument of `NSURLRequest -> Void` with a request that represents the Endpoint.
It's here that you'd do your OAuth signing or whatever. Since you may invoke the 
closure asynchronously, you can use whatever authentication library you like ([example](https://github.com/rheinfabrik/Heimdall.swift)). 
Instead of modifying the request, you could simply log it, instead.

```swift
let requestClosure = { (endpoint: Endpoint<GitHub>, done: NSURLRequest -> Void) in
    let request = endpoint.urlRequest

    // Modify the request however you like.

    done(request)
}
provider = MoyaProvider<GitHub>(requestClosure: requestClosure)
```

This `requestClosure` is useful for modifying properties specific to the `NSURLRequest` or providing information to the request that cannot be known until that request is created, like cookies settings. Note that the `endpointClosure` mentioned above is not intended for this purpose or any request-specific application-level mapping.

This parameter is actually very useful for modifying the request object. 
`NSURLRequest` has many properties you can customize. Say you want to disable 
all cookies on requests:

```swift
{ (endpoint: Endpoint<ArtsyAPI>) -> (NSURLRequest) in
    let request: NSMutableURLRequest = endpoint.urlRequest.mutableCopy() as NSMutableURLRequest
    request.HTTPShouldHandleCookies = false
    return request
}
```

You could also perform logging of network requests, since this closure is 
invoked just before the request is sent to the network. 
