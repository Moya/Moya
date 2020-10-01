# Basic Usage

So how do you use this library? Well, it's pretty easy. Just follow this
template. First, set up an `enum` with all of your API targets. Note that you
can include information as part of your enum. Let's look at a common example. First we create a new file named `MyService.swift`:

```swift
enum MyService {
    case zen
    case showUser(id: Int)
    case createUser(firstName: String, lastName: String)
    case updateUser(id: Int, firstName: String, lastName: String)
    case showAccounts
}
```

This enum is used to make sure that you provide implementation details for each
target (at compile time). You can see that parameters needed for requests can be defined as per the enum cases parameters. The enum *must* additionally conform to the `TargetType` protocol. Let's get this done via an extension in the same file:

```swift
// MARK: - TargetType Protocol Implementation
extension MyService: TargetType {
    var baseURL: URL { URL(string: "https://api.myservice.com")! }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .showUser(let id), .updateUser(let id, _, _):
            return "/users/\(id)"
        case .createUser(_, _):
            return "/users"
        case .showAccounts:
            return "/accounts"
        }
    }
    var method: Moya.Method {
        switch self {
        case .zen, .showUser, .showAccounts:
            return .get
        case .createUser, .updateUser:
            return .post
        }
    }
    var task: Task {
        switch self {
        case .zen, .showUser, .showAccounts: // Send no parameters
            return .requestPlain
        case let .updateUser(_, firstName, lastName):  // Always sends parameters in URL, regardless of which HTTP method is used
            return .requestParameters(parameters: ["first_name": firstName, "last_name": lastName], encoding: URLEncoding.queryString)
        case let .createUser(firstName, lastName): // Always send parameters as JSON in request body
            return .requestParameters(parameters: ["first_name": firstName, "last_name": lastName], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".utf8Encoded
        case .showUser(let id):
            return "{\"id\": \(id), \"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        case .createUser(let firstName, let lastName):
            return "{\"id\": 100, \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        case .updateUser(let id, let firstName, let lastName):
            return "{\"id\": \(id), \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        case .showAccounts:
            // Provided you have a file named accounts.json in your bundle.
            guard let url = Bundle.main.url(forResource: "accounts", withExtension: "json"),
                let data = try? Data(contentsOf: url) else {
                    return Data()
            }
            return data
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
// MARK: - Helpers
private extension String {
    var urlEscaped: String {
        addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data { Data(self.utf8) }
}
```

(The `String` extension is just for convenience – you don't have to use it.)

You can see that the `TargetType` protocol makes sure that each value of the enum translates into a full request. Each full request is split up into the `baseURL`, the `path` specifying the subpath of the request, the `method` which defines the HTTP method and `task` with options to specify parameters to be added to the request.

Note that at this point you have added enough information for a basic API networking layer to work. By default Moya will combine all the given parts into a full request:

```swift
let provider = MoyaProvider<MyService>()
provider.request(.createUser(firstName: "James", lastName: "Potter")) { result in
    // do something with the result (read on for more details)
}

// The full request will result to the following:
// POST https://api.myservice.com/users
// Request body:
// {
//   "first_name": "James",
//   "last_name": "Potter"
// }

provider.request(.updateUser(id: 123, firstName: "Harry", lastName: "Potter")) { result in
    // do something with the result (read on for more details)
}

// The full request will result to the following:
// POST https://api.myservice.com/users/123?first_name=Harry&last_name=Potter
```

Always remember to retain the provider somewhere: if you fail to do so, it will be released automatically, potentially before you receive any response.

The `TargetType` specifies both a base URL for the API and the sample data for
each enum value. The sample data are `Data` instances, and could represent
JSON, images, text, whatever you're expecting from that endpoint.

You can also set up custom endpoints to alter the default behavior to your needs. For example:

```swift
let endpointClosure = { (target: MyService) -> Endpoint in
    return Endpoint(url: URL(target: target).absoluteString, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
}
```

The block you provide will be invoked every time an API call is to be made. Its
responsibility is to return an `Endpoint` instance configured for use by Moya.

Most of the time, this closure is just a straight translation from target,
method and task into an `Endpoint` instance. However, since it's a
closure, it'll be executed at each invocation of the API, so you could do
whatever you want. Say you want to test network error conditions like timeouts, too.

```swift
let failureEndpointClosure = { (target: MyService) -> Endpoint in
    let sampleResponseClosure = { () -> (EndpointSampleResponse) in
        if shouldTimeout {
            return .networkError(NSError())
        } else {
            return .networkResponse(200, target.sampleData)
        }
    }
    return Endpoint(url: URL(target: target).absoluteString, sampleResponseClosure: sampleResponseClosure, method: target.method, task: target.task, httpHeaderFields: target.headers)
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
provider.request(.zen) { result in
    // do something with `result`
}
```

The `request` method is given a `MyService` value (`.zen`), which contains *all the
information necessary* to create the `Endpoint` – or to return a stubbed
response during testing.

The `Endpoint` instance is used to create a `URLRequest` (the heavy lifting is
done via Alamofire), and the request is sent (again - Alamofire).  Once
Alamofire gets a response (or fails to get a response), Moya will wrap the
success or failure in a `Result` enum.  `result` is either
`.success(Moya.Response)` or `.failure(MoyaError)`.

You will need to unpack the data and status code from `Moya.Response`.

```swift
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        let data = moyaResponse.data // Data, your JSON response is probably in here!
        let statusCode = moyaResponse.statusCode // Int - 200, 401, 500, etc

        // do something in your app
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

Take special note: a `.failure` means that the server either didn't *receive the
request* (e.g. reachability/connectivity error) or it didn't send a response
(e.g. the request timed out). If you get a `.failure`, you probably want to
re-send the request after a time delay or when an internet connection is
established.

Once you have a `.success(response)` you might want to filter on status codes or
convert the response data to JSON. `Moya.Response` can help!

###### See more at <https://github.com/Moya/Moya/blob/master/Sources/Moya/Response.swift>

```swift
do {
    try moyaResponse.filterSuccessfulStatusCodes()
    let data = try moyaResponse.mapJSON()
}
catch {
    // show an error to your user
}
```
