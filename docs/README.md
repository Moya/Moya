Moya
====

The README is pretty basic – it describes Moya as "network abstraction layer", 
whatever that means, amirite? I mean, what the heck does that even mean? 

Well, Moya is about working at *high levels of abstraction* in your application. 
It accomplishes this with the following pipline. 

![Pipeline](https://raw.github.com/ashfurrow/Moya/master/web/pipeline.png)

You use Moya to define a Swift `enum` that will be your *target*. Then, the rest
of your app deals *only* with those targets. Targets are usually some action 
that you want to take on the API. 

Optionally, your network layer *can* choose to customize the process of 
transforming a target enum value into an `Endpoint` instance that Moya will use
and finally from that `Endpoint` into an actual `NSURLRequest`. But it *doesn't
have to* – Moya uses sane defaults wherever possible. 

If there is something you want to change about the behaviour of Moya, there is 
probably a way to do it without modifying the library. Moya is designed to be 
super-flexible and accommodate the needs of every developer. It's less of a code
framework and more of a framework of how to think about network requests. 

This document's purpose is to guide you through a simple use case for Moya and
slowly progress to more advanced uses. Remember, if at any point you have a 
question, just [open an issue](http://github.com/AshFurrow/Moya/issues/new) and
we'll get you some help.

Moya Setup
==========

Setup instructions can be found in the [project README](http://github.com/ashfurrow/Moya#Installation).

Basic Usage
===========

Basic usage of Moya can also be found in the [project README](http://github.com/ashfurrow/Moya).
However, let's revisit that a little bit and go into some more detail. 

There's a clear line between what is inside Moya and what is inside your app. 
*You* provide a Swift enum that Moya uses with Swift generics to make API calls.
This enum represents, at a high-level, the different API endpoints you can reach
on your server. In Moya terms, this is called a "*target*." For example:

```swift
enum GitHub {
    case Zen
    case UserProfile(String)
}
```

This enum is yours, but it has a few requirements. It must conform to the 
`MoyaPath` and `MoyaTarget` protocols, which you should using extensions 
*separate* from the main enum declaration.

The `MoyaPath` protocol defines where, relative to a base URL, a member of an 
enum maps to. Extending the example above, we get the following. 

```swift
extension GitHub : MoyaPath {
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
}
```

(Let's assume that we have the `URLEscapedString` property defined in a string 
extension somewhere, as follows. Since this isn't required for Moya – it's just
a convenience for you, it's not part of Moya.)

```swift
private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
}
```

So we have a `path` property defined on any of our API targets. That's nice, but
it's kind of useless unless we know what that path is relative to. For that, 
we'll need a *base URL*. This is where the `MoyaTarget` protocol comes in handy. 

```swift
extension GitHub : MoyaTarget {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com") }
    var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}
```

The `MoyaTarget` protocol requires a `baseURL` property to be defined on the 
enum. Note that this should *not* depend on the value of `self`, but should just
return a single value (if you're using more than one API base URL, separate them
out into separate enums and Moya providers).

Finally, notice the `sampleData` property on the enum. This is a requirement of 
the `MoyaTarget` protocol. Any target you want to hit must provide some non-nil
`NSData` that represents a sample response. This can be used later for tests or
for providing offline support for developers. This *should* depend on `self`. 

OK, now that we have our basic setup done, we can begin to use Moya. You make 
all API requests through a `MoyaProvider` instance, passing in a value of your 
enum. The one required parameter for the `MoyaProvider` initializer is an 
endpoints closure, which is responsible for mapping a value of your enum to a 
concrete `Endpoint` instance. Let's take a look at what one might look like. 

```swift
public func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

let endpointsClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), method: method, parameters: parameters, sampleResponse: .Success(200, target.sampleData))
}
```

This `endpointsClosure` is about as simple as you can get. You might be asking 
yourself "why bother with this mapping?" That's a great question. The point of 
this is to take the high-level concept of the enum (which is usually about 
accomplishing some task on the API) and turning it into an `Endpoint`, a class
which encapsulates the information needed to actually make that call, including
the URL of the request, the HTTP method, the parameters to be send to the API,
and the sample data and sample response code for that target. We separate the
two concepts so that the targets are unaware of the possible differences between
each other in terms of HTTP methods or additional parameters. We'll get into a 
possible use case in the "Advanced Use" section. 

Finally, with our `endpintsClosure`, we can create a `MoyaProvider` instance. 

```swift
// Tuck this away somewhere where it'll be visible to anyone who wants to use it
var provider: MoyaProvider<GitHub>!

// Create this instance at app launch
let provider = MoyaProvider(endpointsClosure: endpointsClosure)
```

From now on, using the provider is as simple as calling the `request` method 
with whichever target you want. 

```swift
provider.request(.Zen, completion: { (data, error) in
    if let data = data {
        // do something with the data
    }
})
```

There are two other, optional parameters to the `MoyaProvider` initializer: the
`endpointResolver` and `stubResponses`. Both are constants and cannot be changed
after the provider is created. 

`stubResponses` is very straightforward: should the provider access the API or
should it return the stubbed data? The `endpointResolver` is a little more 
complicated. This closure is responsible for mapping an `Endpoint` instance into
the actual `NSURLRequest` that will be sent to the API. The default 
implementation that Moya uses just returns the `urlRequest` property on the 
endpoint, which constructs a URL request at its URL with the HTTP method and 
URL-mapped properties. It's here that you have an opportunity to change all or
some of the requests made to your API, or to log network traffic, or whatever. 
There are more details and examples in the "Request Mapping" section below. 

Remember, *where* you put all this – the enum, the enum extensions, any 
Foundation extensions you need, and the provider itself, are completely up to 
you. You can check out [Artsy's implementation](https://github.com/Artsy/eidolon/Kiosk/AppNetworking/ArtsyAPI.swift)
for an example of how we did it. 

Advanced Use
============

So we've covered the basics so far: we have a Moya provider that can do things, 
and you know how to map targets to endpoints. This section will show you how to
further customize your use of Moya by specifying target-specific settings and by 
specifying a mapping from `Endpoint`s to `NSURLRequest`s. Let's get started. 

Endpoint Mapping 
----------------

Mapping a target into an endpoint was covered above, but it was a simple 
example. If you recall, it looked something like this. 

```swift
let endpointsClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), method: method, parameters: parameters, sampleResponse: .Success(200, target.sampleData))
}
```

It creates an `Endpoint` with a URL constructed from the target's `baseURL` and 
`path` properties, uses the HTTP method that was given to it (Moya's `request`
method defaults this to GET), and any parameters that were passed into the 
`request` method (which defaults to an empty dictionary). The parameters here 
are key. 

In this simple example, the parameters are passed directly into the `Endpoint`,
which will eventually resolve to parameters passed with the URL request. You 
have the opportunity here to instead provide your own parameters. This means 
that your application code can use one set of parameters that are mapped 
separately to actual API parameters later on. Pretty cool. 

By default, `Endpoint` instances use the `.URL` type parameter encoding. You
can specify how you'd like to encode parameters on a target-by-target basis in
the `endpointsClosure` using the optional `parameterEncoding` parameter of the
`Endpoint` initializer. 

There are four parameter encoding types: `.URL`, `.JSON`, `.PropertyList`, and
`.Custom`, which map directly to the corresponding types in Alamofire. 

You can add parameters or HTTP header fields in this closure. For example, we 
may wish to set our application name in the HTTP header fields for server-side
analytics. 

```swift
let endpointsClosure = { (target: MyTarget, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<MyTarget> in
    let endpoint: Endpoint<MyTarget> = Endpoint<MyTarget>(URL: url(target), sampleResponse: .Success(200, target.sampleData), method: method, parameters: parameters)
    return endpoint.endpointByAddingHTTPHeaderFields(["APP_NAME": "MY_AWESOME_APP"])
}
```

This also means that you can provide additional parameters to some or all of 
your endpoints. For example, say that there is an authentical token we need for 
all values of the hypothetical `MyTarget` target, with the exception of the 
target that actually does the authentication. We could construct an 
`endpointsClosure` resembling the following. 

```swift
let endpointsClosure = { (target: MyTarget, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<MyTarget> in
    let endpoint: Endpoint<MyTarget> = Endpoint<MyTarget>(URL: url(target), sampleResponse: .Success(200, target.sampleData), method: method, parameters: parameters)

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
 
Request Mapping
---------------

As we mentioned earlier, the purpose of this library is not really to provide a
coding framework with which to access the network – that's Alamofire's job. 
Instead, Moya is about a way to frame your thoughts about network access and 
provide compile-time checking of well-defined network targets. You've already 
seen how to map targets into endpoints using the `endpointsClosure` parameter
of the `MoyaProvider` initializer. That let you create an `Endpoint` instance
that Moya will use to reason about the network API call. At some point, that
`Endpoint` must be resolved into an actual `NSURLRequest` to give to Alamofire. 
That's what the `endpointResolver` parameter is for. 

The `endpointResolver` is an optional, last-minute way to modify the request 
that hits the network. It has a default value of `DefaultEnpointResolution()`, 
which simply uses the `urlRequest` property of the `Endpoint` instance. 

This closure receives an `Endpoint` instance and is responsible for returning a
`NSURLRequest` that represents the resources to be accessed. It's here that 
you'd do your OAuth signing or whatever. Since you return an `NSURLRequest`, you
can use whatever general-purpose authentication library you want. You can return 
the `urlRequest` property of the instance that you're passed in, which would not 
change the request at all. That could be useful for logging, for example. 

Note that the `endpointResolver` is *not* intended to be used for any sort of 
application-level mapping. This closure is really about modifying properties 
specific to the `NSURLRequest`, or providing information to the request that 
cannot be known until that request is created, like an OAuth signature. 

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
