Targets
=======

Using Moya starts with defining a target – typically some `enum` that conforms 
to the `TargetType` protocol. Then, the rest of your app deals *only* with 
those targets. Targets are some action that you want to take on the API, 
like "`FavouriteTweet(tweetID: String)`". 

Here's an example:

```swift
public enum GitHub {
    case Zen
    case UserProfile(String)
    case UserRepositories(String)
}
```

Targets must conform to `TargetType`. The `TargetType` protocol requires a 
`baseURL` property to be defined on the enum. Note that this should *not* depend 
on the value of `self`, but should just return a single value (if you're using 
more than one API base URL, separate them out into separate enums and Moya 
providers). Here's the beginning of our extension:

```swift
extension GitHub: TargetType {
    public var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
```

This protocol specifies the locations of 
your API endpoints, relative to its base URL (more on that below). 

```swift
    public var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        case .UserRepositories(let name):
            return "/users/\(name.URLEscapedString)/repos"
        }
    }
```

Note: we're cheating here and using a `URLEscapedString` extension on String. 
A sample implementation is given at the end of this document. 

OK, cool. So now we need to have a `method` for our enum values. In our case, we
are always using the GET HTTP method, so this is pretty easy:

```swift
    public var method: Moya.Method {
        return .GET
    }
```

Nice. If some of your endpoints require POST or another method, then you can switch
on `self` to return the appropriate value. This kind of switching technique is what 
we saw when calculating our `path` property.

Our `TargetType` is shaping up, but we're not done yet. We also need a `parameters`
computed property that returns parameters defined by the enum case. Here's an example:

```swift
    public var parameters: [String: AnyObject]? {
        switch self {
        case .UserRepositories(_):
            return ["sort": "pushed"]
        default:
            return nil
        }
    }
```

Unlike our `path` property earlier, we don't actually care about the associated values
of our `UserRepositories` case, so we use the Swift `_` ignored-value symbol.

Finally, notice the `sampleData` property on the enum. This is a requirement of 
the `TargetType` protocol. Any target you want to hit must provide some non-nil
`NSData` that represents a sample response. This can be used later for tests or
for providing offline support for developers. This *should* depend on `self`. 

```swift
    public var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserRepositories(let name):
            return "[{\"name\": \"Repo Name\"}]".dataUsingEncoding(NSUTF8StringEncoding)!
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
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}
```
