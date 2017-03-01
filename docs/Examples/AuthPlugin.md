# Creating an Authorization Plugin

It is relatively common for API requests to be authorized via a JWT (JSON Web
Token) or another type of access token. In this example we will create a plugin
that can be used to add a jwt to requests. First let's look at a simple example
of how we might add a jwt to a request via a plugin:

```swift
struct AuthPlugin: PluginType {
  let token: String

  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    var request = request
    request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
    return request
  }
}

let provider = MoyaProvider<Target>(plugins: [AuthPlugin(token: "eyeAm.AJsoN.weBTOKen")])
```

Now let's look at a more complex example where we might not have access to the
jwt when we create the plugin and not all requests need to be signed. We can
accomplish this by extending the `TargetType` protocol to provide information on
whether or not authorization is needed and also taking a closure for providing
a token.

```swift
class TokenSource {
  var token: String? = nil
  init() { }
}

protocol AuthorizedTargetType: TargetType {
  var needsAuth: Bool { get }
}

struct AuthPlugin: PluginType {
  let tokenClosure: () -> String?

  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    guard
      let token = tokenClosure(),
      let target = target as? AuthorizedTargetType,
      target.needsAuth
    else {
      return request
    }

    var request = request
    request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
    return request
  }
}

let source = TokenSource()
let provider = MoyaProvider<Target>(
  plugins: [
    AuthPlugin(tokenClosure: { return source.token })
  ]
)

source.token = "eyeAm.AJsoN.weBTOKen"
```
