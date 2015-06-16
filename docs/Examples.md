Examples
================

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
target (at compile time). The enum *must* conform to the `MoyaTarget` protocol. 
Let's take a look at what that might look like.

```swift
private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
}

extension GitHub : MoyaTarget {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com") }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject] {
        return [:]
    }
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

let endpointClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
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
let failureEndpointClosure = { (target: GitHub, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<GitHub> in
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
let provider = MoyaProvider(endpointClosure: endpointClosure)
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
