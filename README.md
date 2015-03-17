[![Build Status](https://travis-ci.org/ashfurrow/Moya.svg)](https://travis-ci.org/ashfurrow/Moya)

![Moya Logo](https://raw.github.com/ashfurrow/Moya/master/web/moya_logo_github.png)

So the basic idea is that we want some network abstraction layer to satisfy
all of the requirements listed [here](https://github.com/artsy/eidolon/issues/9).
Mainly:

- Treat test stubs as first-class citizens.
- Only endpoints clearly defined through Moya can be accessed through Moya,
enforced by the compiler.
- Allow iterating through all potential API requests at runtime for API sanity
checks.
- Keep track of inflight requests and don't support duplicates.

Super-cool. We actually go a bit farther than other network libraries by
abstracting the API endpoints away, too. Instead of dealing with endpoints
(URLS) directly, we use *targets*, which represent actions to be take on the
API. This is beneficial if one action can hit different endpoints; for example,
if you want to GET a user profile, but the endpoint differs depending on if that
user is a friend or not. Hey – I don't write these APIs, I just use 'em.

Sample Project
--------------

There's a sample project in the Sample directory. Make sure to run the [installation
instructions](#installation) below, since it relies a pre-release version of CocoaPods. 

Project Status
--------------

This is nearing a 1.0 release, though it works now. We're using it in [Artsy's
new auction app](https://github.com/Artsy/eidolon).

Currently, we support Xcode 6.1.1. 

Installation
------------

This project has some dependencies, which are currently managed by a pre-release
version of CocoaPods (0.36 Beta 1). Add the following lines to your Podfile:

```rb
pod 'Moya'

# Include the following only if you want to use ReactiveCocoa extensions with Moya
pod 'ReactiveCocoa', '3.0.0-alpha.1'
pod 'Moya/Reactive'
```

Then run `pod install`. In any file you'd like to use Moya in, don't forget to
import the framework with `import Moya`.

Use
---

So how do you use this library? Well, it's pretty easy. Just follow this
template. First, set up an `enum` with all of your API targets. Note that you
can include information as part of your enum. Let's look at a simple example.

```swift
enum GitHub {
    case Zen
    case UserProfile(String)
}
```

This enum is used to make sure that you provide implementation details for each
target (at compile time). The enum *must* conform to the `MoyaTarget` protocol,
and by extension, the `MoyaPath` one as well. Let's take a look at what that
might look like.

```swift
private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
}

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

(The `String` extension is just for convenience – you don't have to use it.)

You can see that the `MoyaPath` protocol translates each value of the enum into
a relative URL, which can use values embedded in the enum. Super cool.
The `MoyaTarget` specifies both a base URL for the API and the sample data for
each enum value. The sample data are `NSData` instances, and could represent
JSON, images, text, whatever you're expecting from that endpoint.

Next, we'll set up the endpoints for use with our API.

```swift
public func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

let endpointsClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), method: method, parameters: parameters, sampleResponse: .Success(200, target.sampleData))
}
```

The block you provide will be invoked every time an API call is to be made. Its
responsibility is to return an `Endpoint` instance configured for use by Moya.
The `parameters` parameter is passed into this block to allow you to configure
the `Endpoint` instance – these parameters are *not* automatically passed onto
the network request, so add them to the `Endpoint` if they should be. They could
be some data internal to the app that help configure the `Endpoint`. In this
example, though, they're just passed right through.

Most of the time, this closure is just a straight translation from target,
method, and parameters, into an `Endpoint` instance. However, since it's a
closure, it'll be executed at each invocation of the API, so you could do
whatever you want. Say you want to test errors, too.

```swift
let failureEndpointsClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
    let sampleResponse = { () -> (EndpointSampleResponse) in
        if sendErrors {
            return .Error(404, NSError())
        } else {
            return .Success(200, target.sampleData)
        }
    }()
    return Endpoint<GitHub>(URL: url(target), method: method, parameters: parameters, sampleResponse: sampleResponse)
}
```

Notice that returning sample data is *required*. One of the key benefits of Moya
is that it makes testing the app or running the app using stubbed responses for
API calls really easy.

Great, now we're all set. Just need to create our provider.

```swift
// Tuck this away somewhere where it'll be visible to anyone who wants to use it
var provider: MoyaProvider<GitHub>!

// Create this instance at app launch
let provider = MoyaProvider(endpointsClosure: endpointsClosure)
```

Neato. Now how do we make a request?

```swift
provider.request(.Zen, completion: { (data, statusCode, response, error) in
    if let data = data {
        // do something with the data
    }
})
```

The `request` method is given a `GitHub` value and, optionally, an HTTP method
and parameters for the endpoint closure.

ReactiveCocoa Extensions
------------------------

Even cooler are the ReactiveCocoa extensions. It immediately returns a  
`RACSignal` that you can subscribe to or bind or map or whatever you want to
do. To handle errors, for instance, we could do the following:

```swift
provider.request(.UserProfile("ashfurrow")).subscribeNext({ (object) -> Void in
    image = UIImage(data: object as? NSData)
}, error: { (error) -> Void in
    println(error)
})
```

In addition to the option of using signals instead of callback blocks, there are
also a series of signal operators that will attempt to map the data received 
from the network response into either an image, some JSON, or a string, with 
`mapImage()`, `mapJSON()`, and `mapString()`, respectively. If the mapping is
unsuccessful, you'll get an error on the signal. You also get handy methods for
filtering out certain status codes. This means that you can place your code for 
handling API errors like 400's in the same places as code for handling invalid 
responses. 

License
-------

Moya is released under an MIT license. See LICENSE for more information.
