Targets
=======

Using Moya starts with defining a target – typically some `enum` that conforms
to the `TargetType` protocol. Then, the rest of your app deals *only* with
those targets. Targets are some action that you want to take on the API,
like "`favoriteTweet(tweetID: String)`".

Here's an example:

```swift
public enum GitHub {
    case zen
    case userProfile(String)
    case userRepositories(String)
    case branches(String, Bool)
}
```

Targets must conform to `TargetType`. The `TargetType` protocol requires a
`baseURL` property to be defined on the enum. Note that this should *not* depend
on the value of `self`, but should just return a single value (if you're using
more than one API base URL, separate them out into separate enums and Moya
providers). Here's the beginning of our extension:

```swift
extension GitHub: TargetType {
    public var baseURL: URL { return URL(string: "https://api.github.com")! }
}
```

This protocol specifies the locations of
your API endpoints, relative to its base URL (more on that below).

```swift
public var path: String {
    switch self {
    case .zen:
        return "/zen"
    case .userProfile(let name):
        return "/users/\(name.urlEscaped)"
    case .userRepositories(let name):
        return "/users/\(name.urlEscaped)/repos"
    case .branches(let repo, _)
        return "/repos/\(repo.urlEscaped)/branches"
    }
}
```

Notice that we're ignoring the second associated value of our `branches` Target using the Swift `_` ignored-value symbol. That's because we don't need it to define the `branches` path.
Note: we're cheating here and using a `urlEscaped` extension on String.
A sample implementation is given at the end of this document.

OK, cool. So now we need to have a `method` for our enum values. In our case, we
are always using the GET HTTP method, so this is pretty easy:

```swift
public var method: Moya.Method {
    return .get
}
```

Nice. If some of your endpoints require POST or another method, then you can switch
on `self` to return the appropriate value. This kind of switching technique is what
we saw when calculating our `path` property.

Our `TargetType` is shaping up, but we're not done yet. We also need a `parameters`
computed property that returns parameters defined by the enum case. Here's an example:

```swift
public var parameters: [String: Any]? {
    switch self {
    case .userRepositories(_):
        return ["sort": "pushed"]
    case .branches(_, let protected):
        return ["protected": "\(protected)"]
    default:
        return nil
    }
}
```

Unlike our `path` property earlier, we don't actually care about the associated values of our `userRepositories` case, so we use the Swift `_` ignored-value symbol.
Let's take a look at the `branches` case: we'll use our `Bool` associated value (`protected`) as a request parameter by assigning it to the `"protected"` key. We're parsing our `Bool` value to `String`. (Alamofire does not encode `Bool` parameters automatically, so we need to do it by our own).

While we are talking about parameters, we need to indicate how we want our
parameters to be encoded into our request. We do this by returning a
`ParameterEncoding` from a `parameterEncoding` computed property. Out of the
box, Moya has `URLEncoding`, `JSONEncoding`, and `PropertyListEncoding`. You can
also create your own encoder that conforms to `ParameterEncoding` (e.g.
`XMLEncoder`).

```swift
public var parameterEncoding: ParameterEncoding {
    switch self {
    case .zen:
        return JSONEncoding.default
    default:
        return URLEncoding.default
    }
}
```

Notice the `sampleData` property on the enum. This is a requirement of
the `TargetType` protocol. Any target you want to hit must provide some non-nil
`Data` that represents a sample response. This can be used later for tests or
for providing offline support for developers. This *should* depend on `self`.

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

Finally, our `TargetType` has a `task` property that represents how you are sending / receiving data. This can be either `.request`, `.upload` or `.download`, and allows you to add data, files and streams to the request body.

```swift
public var task: Task {
    switch self {
    case .zen, .userProfile, .userRepositories, .branches:
        return .request
    }
}
```

After this setup, creating our [Provider](Providers.md) is as easy as the following:

```swift
let GitHubProvider = MoyaProvider<GitHub>()
```

Escaping URLs
-------------

Here's an example extension that allows you to easily escape normal strings
"like this" to URL-encoded strings "like%20this":

```swift
extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}
```
