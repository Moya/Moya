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
target (at compile time). The enum *must* conform to the `TargetType` protocol.
Let's take a look at what that might look like.

```swift
private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
}

extension GitHub: TargetType {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: Moya.Method {
        // all requests in this example will use GET.  Usually you would switch
        // on the enum, like we did in `var path: String`
        return .GET
    }
    var parameters: [String: AnyObject]? {
        return nil
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
The `TargetType` specifies both a base URL for the API and the sample data for
each enum value. The sample data are `NSData` instances, and could represent
JSON, images, text, whatever you're expecting from that endpoint.

Next, we'll set up the endpoints for use with our API.

```swift
public func url(route: TargetType) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

let endpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
}
```

The block you provide will be invoked every time an API call is to be made. Its
responsibility is to return an `Endpoint` instance configured for use by Moya.
`parameters` is passed into this block to allow you to configure the `Endpoint`
instance – these parameters are *not* automatically passed onto the network
request, so add them to the `Endpoint` if they should be. They could be some
data internal to the app that help configure the `Endpoint`. In this example,
though, they're just passed right through.

Most of the time, this closure is just a straight translation from target,
method, and parameters, into an `Endpoint` instance. However, since it's a
closure, it'll be executed at each invocation of the API, so you could do
whatever you want. Say you want to test network error conditions like timeouts, too.

```swift
let failureEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    let sampleResponseClosure = { () -> (EndpointSampleResponse) in
        if shouldTimeout {
            return .NetworkError(NSError())
        } else {
            return .NetworkResponse(200, target.sampleData)
        }
    }
    return Endpoint<GitHub>(URL: url(target), sampleResponseClosure: sampleResponseClosure, method: target.method, parameters: target.parameters)
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
provider.request(.Zen, completion: { result in
    // do something with `result`
})
```

The `request` method is given a `GitHub` value (`.Zen`), which contains *all the
information necessary* to create the `Endpoint` – or to return a stubbed
response during testing.

The `Endpoint` instance is used to create a `NSURLRequest` (the heavy lifting is
done via Alamofire), and the request is sent (again - Alamofire).  Once
Alamofire gets a response (or fails to get a response), Moya will wrap the
success or failure in a `Result` enum.  `result` is either
`.Success(Moya.Response)` or `.Failure(Moya.Error)`.

You will need to unpack the data and status code from `Moya.Response`.

```swift
provider.request(.Zen) { result in
    switch result {
    case let .Success(moyaResponse):
        let data = moyaResponse.data // NSData, your JSON response is probably in here!
        let statusCode = moyaResponse.statusCode // Int - 200, 401, 500, etc

        // do something in your app
    case let .Failure(error):
        // TODO: handle the error ==  best. comment. ever.
    }
}
```

Take special note: a `.Failure` means that the server either didn't *receive the
request* (e.g. reachability/connectivity error) or it didn't send a response
(e.g. the request timed out).  If you get a `.Failure`, you probably want to
re-send the request after a time delay or when an internet connection is
established.

Once you have a `.Success(response)` you might want to filter on status codes or
convert the response data to JSON. `Moya.Response` can help!

###### see more at <https://github.com/Moya/Moya/blob/master/Source/Response.swift>

```swift
do {
    try moyaResponse.filterSuccessfulStatusCodes()
    let data = try moyaResponse.mapJSON()
}
catch {
    // show an error to your user
}
```

Moving towards a real-world example, you might want to wrap the **request ->
result** cycle in your own network adapter, to make it a little easier to
convert successful responses, show error messages and re-attempt after network
failures.

```swift
struct Network {
    static let provider = MoyaProvider(endpointClosure: endpointClosure)

    static func request(
        target: Github,
        success successCallback: (JSON) -> Void,
        error errorCallback: (statusCode: Int) -> Void,
        failure failureCallback: (Moya.Error) -> Void
    ) {
        provider.request(target) { result in
            switch result {
            case let .Success(response):
                do {
                    try response.filterSuccessfulStatusCodes()
                    let json = try JSON(response.mapJSON())
                    successCallback(json)
                }
                catch error {
                    errorCallback(error)
                }
            case let .Failure(error):
                if target.shouldRetry {
                    retryWhenReachable(target, successCallback, errorCallback, failureCallback)
                }
                else {
                    failureCallback(error)
                }
            }
        }
    }
}

// usage:
Network.request(.Zen, success: { zen in
    showMessage(zen)
}, error: { err in
    showError(err)
}, failure: { _ in
    // oh well, no network apparently
})
```
