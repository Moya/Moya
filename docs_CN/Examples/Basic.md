# Basic Usage

那么您如何来使用这个库呢? 额，相当简单！ 只要按照这个模板来做就可以了. 首先, 为你的所有的API目标来创建一个`enum` 。注意您可以将信息包含在enum中。让我来看一个常见的例子。 首先我们创建一个名为 `MyService.swift`的新文件:

```swift
enum MyService {
    case zen
    case showUser(id: Int)
    case createUser(firstName: String, lastName: String)
    case updateUser(id: Int, firstName: String, lastName: String)
    case showAccounts
}
```

这个enum用来确保为每个target（在编译时）提供实现细节. 您可以看到请求所需要的参数可以被定义为每个enum的case参数。这个enum必须遵循`TargetType`协议. 让我们在同一个文件中，通过扩展来实现它:

```swift
// MARK: - TargetType Protocol Implementation
extension MyService: TargetType {
    var baseURL: URL { return URL(string: "https://api.myservice.com")! }
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

    var utf8Encoded: Data {
        Data(self.utf8)
    }
}
```

(`String` 扩展仅仅为了方便– 你没必须非得使用它.)

您可以看到 `TargetType` 协议保证了每个enum的值被转化为了一个完整的request。每个完整的request 被分割成了 `baseURL`, 指定request子路径的`path` , 定义HTTP方法的 `method` 和指定了request的参数和参数编码的 `task` .

请注意，此时您已经为基本API网络层添加了足够的信息。默认情况下，Moya将所有给定的部分合并成一个完整的请求。（ps：译者注，还剩余一个sampleData属性需要实现，这个是用于本地测试的，属于附加的）

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

`TargetType` 为API指定了一个base URL 同时也为每个enum值指定了sample data 。 这个 sample data 个是 `Data` 实例对象, 它可以表示
JSON, images, text, 或者任何您希望从endpoint得到的.

你也可以创建自定义的endpoint来替代默认的行为，从而来满足你的需求。比如:

```swift
let endpointClosure = { (target: MyService) -> Endpoint in
    return Endpoint(url: URL(target: target).absoluteString, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task)
}
```

每当一个API被调用的时候，您提供的这个闭包将会被执行. 它负责返回一个 `Endpoint` 实例对象，用来配置Moya.

多数情况下, 这个闭包仅仅直接从target，method和task转化为一个 `Endpoint` 实例对象. 然而, 由于它是一个闭包, 它将在每次调用API时被执行, 所以你可以做任何你想要的.  比如,您想在里面测试网络错误,如超时等.

```swift
let failureEndpointClosure = { (target: MyService) -> Endpoint in
    let sampleResponseClosure = { () -> (EndpointSampleResponse) in
        if shouldTimeout {
            return .networkError(NSError())
        } else {
            return .networkResponse(200, target.sampleData)
        }
    }
    return Endpoint(url: URL(target: target).absoluteString, sampleResponseClosure: sampleResponseClosure, method: target.method, task: target.task)
}
```

注意返回的sample data是*必须的*. Moya的一个关键好处是，它让测试的app和运行的app在调用API时使用stubbed响应是非常的容易
。

相当好, 现在我们已经设置完了. 剩余就是需要创建我们的provide.

```swift
// Tuck this away somewhere where it'll be visible to anyone who wants to use it
var provider: MoyaProvider<MyService>!

// Create this instance at app launch
let provider = MoyaProvider(endpointClosure: endpointClosure)
```

Neato. 现在我们如何发送一个请求呢?

```swift
provider.request(.zen) { result in
    // do something with `result`
}
```

`request` 方法被传递了一个 `MyService` 值 (`.zen`), 它包含了用来创建 `Endpoint`的*所有必须的信息*  – 或者在测试期间返回一个stubbed。

`Endpoint` 实例对象被用来创建一个`URLRequest` (繁重的工作已通过Alamofire完成的), 并且request被发送 (也是被 - Alamofire).  一旦
Alamofire 得到了一个响应 (或者没有得到响应), Moya 将用enum`Result`类型包裹成功或者失败.  `result` 要么是
`.success(Moya.Response)` 要么是 `.failure(MoyaError)`.

你需要从`Moya.Response`解包数据和状态码。

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

特别需要注意的是: a一个`.failure` 意味着要么服务器没有收到请求（比如，可达性/连接错误），要么是服务器没有发送响应（比如，请求超时）. 如果您收到一个 `.failure`, 您有可能希望在一段时间后或者当网络连接可用时重新发送这个请求。


一旦您收到一个 `.success(response)` 您可能想过滤状态码或者把响应数据转为JSON . `Moya.Response` 可以用来做此事!

###### 更多查看 <https://github.com/Moya/Moya/blob/master/Sources/Moya/Response.swift>

```swift
do {
    try moyaResponse.filterSuccessfulStatusCodes()
    let data = try moyaResponse.mapJSON()
}
catch {
    // show an error to your user
}
```
