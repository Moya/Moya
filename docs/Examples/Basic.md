Basic Usage
===========

So how do you use this library? Well, it's pretty easy. Just follow this
template. First, set up an `enum` with all of your API targets. Note that you
can include information as part of your enum. Let's look at a common example. First we create a new file named `MyService.swift`:

```swift
enum MyService {
    case Zen
    case ShowUser(id: Int)
    case CreateUser(firstName: String, lastName: String)
}
```

This enum is used to make sure that you provide implementation details for each
target (at compile time). You can see that parameters needed for requests can be defined as per the enum cases parameters. The enum *must* additionally conform to the `TargetType` protocol. Let's get this done via an extension in the same file:

```swift
// MARK: - TargetType Protocol Implementation
extension MyService: TargetType {
    var baseURL: NSURL { return NSURL(string: "https://api.myservice.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .ShowUser(let id):
            return "/users/\(id)"
        case .CreateUser(_, _):
            return "/users"
        }
    }
    var method: Moya.Method {
        switch self {
        case .Zen, .ShowUser:
            return .GET
        case .CreateUser:
            return .POST
        }
    }
    var parameters: [String: AnyObject]? {
        switch self {
        case .Zen, .ShowUser:
            return nil
        case .CreateUser(let firstName, let lastName):
            return ["first_name": firstName, "last_name": lastName]
        }
    }
    var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".UTF8EncodedData
        case .ShowUser(let id):
            return "{\"id\": \(id), \"first_name\": \"Harry\", \"last_name\": \"Potter\"}".UTF8EncodedData
        case .CreateUser(let firstName, let lastName):
            return "{\"id\": 100, \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".UTF8EncodedData
        }
    }
}

// MARK: - Helpers
private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    var UTF8EncodedData: NSData {
        return self.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
```

(The `String` extension is just for convenience – you don't have to use it.)

You can see that the `TargetType` protocol makes sure that each value of the enum translates into a full request. Each full request is split up into the `baseURL`, the `path` specifying the subpath of the request, the `method` which defines the HTTP method and optionally `parameters` to be added to the request.

Note that at this point you have added enough information for a basic API networking layer to work. By default Moya will combine all the given parts into a full request:

```swift
let provider = MoyaProvider<MyService>()
provider.request(.CreateUser(firstName: "James", lastName: "Potter")) { result in
    // do something with the result (read on for more details)
}

// The full request will result to the following (by default):
// POST https://api.myservice.com/users?first_name=James&last_name=Potter
```

The `TargetType` specifies both a base URL for the API and the sample data for
each enum value. The sample data are `NSData` instances, and could represent
JSON, images, text, whatever you're expecting from that endpoint.

You can also set up custom endpoints to alter the default behavior to your needs. For example:

```swift
public func url(route: TargetType) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

let endpointClosure = { (target: MyService) -> Endpoint<MyService> in
    return Endpoint<MyService>(URL: url(target), sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
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
let failureEndpointClosure = { (target: MyService) -> Endpoint<MyService> in
    let sampleResponseClosure = { () -> (EndpointSampleResponse) in
        if shouldTimeout {
            return .NetworkError(NSError())
        } else {
            return .NetworkResponse(200, target.sampleData)
        }
    }
    return Endpoint<MyService>(URL: url(target), sampleResponseClosure: sampleResponseClosure, method: target.method, parameters: target.parameters)
}
```

Notice that returning sample data is *required*. One of the key benefits of Moya
is that it makes testing the app or running the app using stubbed responses for
API calls really easy.

Great, now we're all set. Just need to create our provider.

```swift
// Tuck this away somewhere where it'll be visible to anyone who wants to use it
var provider: MoyaProvider<MyService>!

// Create this instance at app launch
let provider = MoyaProvider(endpointClosure: endpointClosure)
```

Neato. Now how do we make a request?

```swift
provider.request(.Zen) { result in
    // do something with `result`
}
```

The `request` method is given a `MyService` value (`.Zen`), which contains *all the
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
