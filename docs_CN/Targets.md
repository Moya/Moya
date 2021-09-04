# Targets

Moya的使用始于定义一个target——典型的是定义一个符合`TargetType` 协议的枚举类型。然后,您的APP剩下的只处理那些target。Target是一些你希望在API上采取的动作，比如 "`favoriteTweet(tweetID: String)`"。

这儿有个示例:

```swift
public enum GitHub {
    case zen
    case userProfile(String)
    case userRepositories(String)
    case branches(String, Bool)
}
```

Targets必须遵循 `TargetType`协议。 `TargetType`协议要求一个`baseURL`属性必须在这个枚举中定义，注意它不应该依赖于`self`的值，而应该直接返回单个值（如果您多个base URL，它们独立的分割在枚举和Moya中）。下面开始我们的扩展:

```swift
extension GitHub: TargetType {
    public var baseURL: URL { URL(string: "https://api.github.com")! }
}
```

这个协议指定了你API端点相对于它base URL的位置（下面有更多的）

```swift
public var path: String {
    switch self {
    case .zen:
        return "/zen"
    case .userProfile(let name):
        return "/users/\(name.urlEscaped)"
    case .userRepositories(let name):
        return "/users/\(name.urlEscaped)/repos"
    case .branches(let repo, _):
        return "/repos/\(repo.urlEscaped)/branches"
    }
}
```

注意我们使用“`_` ”符号，忽略了分支中的第二个关联值。这是因为我们不需要它来定义分支的路径。注意这儿我们使用了String的扩展`urlEscaped`。
这个文档的最后会给出一个实现的示例。

OK, 非常好. 现在我们需要为枚举定义一个`method`, 这儿我们始终使用GET方法,所以这相当的简单:

```swift
public var method: Moya.Method {
    return .get
}
```

非常好. 如果您的一些端点需要POST或者其他的方法，那么您需要使用switch来分别返回合适的值。swith的使用在上面 `path`属性中已经看到过了。

我们的`TargetType`快成形了,但是我们还没有完成。我们需要一个`task`的计算属性。它返回可能带有参数的task类型。

下面是一个示例:

```swift
public var task: Task {
    switch self {
    case .userRepositories:
        return .requestParameters(parameters: ["sort": "pushed"], encoding: URLEncoding.default)
    case .branches(_, let protected):
        return .requestParameters(parameters: ["protected": "\(protected)"], encoding: URLEncoding.default)
    default:
        return .requestPlain
    }
}
```

不像我们先前的`path`属性, 我们不需要关心 `userRepositories` 分支的关联值, 所以我们省略了括号。
让我们来看下 `branches` 分支: 我们使用 `Bool` 类型的关联值(`protected`) 作为请求的参数值，并且把它赋值给了字典中的 `"protected"` 关键字。我们转换了 `Bool` 到 `String`。(Alamofire 没有自动编码`Bool`参数, 所以需要我们自己来完成这个工作).

当我们谈论参数时，这里面隐含了参数需要被如何编码进我们的请求。我们需要通过`.requestParameters`中的`ParameterEncoding`参数来解决这个问题。Moya有 `URLEncoding`, `JSONEncoding`, and `PropertyListEncoding`可以直接使用。您也可以自定义编码，只要遵循`ParameterEncoding`协议即可（比如，`XMLEncoder`）。

 `task` 属性代表你如何发送/接受数据，并且允许你向它添加数据、文件和流到请求体中。这儿有几种`.request` 类型:
 
- `.requestPlain` 没有任何东西发送
- `.requestData(_:)` 可以发送 `Data` (useful for `Encodable` types in Swift 4)
- `.requestJSONEncodable(_:)`
- `.requestParameters(parameters:encoding:)` 发送指定编码的参数
- `.requestCompositeData(bodyData:urlParameters:)` & `.requestCompositeParameters(bodyParameters:bodyEncoding:urlParameters)` which allow you to combine url encoded parameters with another type (data / parameters)

同时, 有三个上传的类型: 

- `.uploadFile(_:)` 从一个URL上传文件, 
- `.uploadMultipart(_:)` multipart 上传
- `.uploadCompositeMultipart(_:urlParameters:)` 允许您同时传递 multipart 数据和url参数

还有 两个下载类型: 
- `.downloadDestination(_:)` 单纯的文件下载
- `.downloadParameters(parameters:encoding:destination:)` 请求中携带参数的下载。


下面, 注意枚举中的`sampleData`属性。 这是`TargetType`协议的一个必备属性。这个属性值可以用来后续的测试或者为开发者提供离线数据支持。这个属性值依赖于 `self`.

```swift
public var sampleData: Data {
    switch self {
    case .zen:
        return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
    case .userProfile(let name):
        return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
    case .userRepositories(let name):
        return "[{\"name\": \"Repo Name\"}]".data(using: String.Encoding.utf8)!
    case .branches:
        return "[{\"name\": \"master\"}]".data(using: String.Encoding.utf8)!
    }
}
```

最后, `headers` 属性存储头部字段，它们将在请求中被发送。

```swift
public var headers: [String: String]? {
    return ["Content-Type": "application/json"]
}
```

在这些配置后, 创建我们的 [Provider](Providers.md) 就像下面这样简单:

```swift
let GitHubProvider = MoyaProvider<GitHub>()
```

URLs的转义
-------------

这个扩展示例，需要您很容易的把常规字符串"like this" 转义成url编码的"like%20this"字符串:

```swift
extension String {
    var urlEscaped: String {
        addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}
```
