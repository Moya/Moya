# 创建一个授权插件

使用JWT或者token给API请求授权是相当常见的。在这个示例中我们将创建一个带有jwt的请求。首先，让我们来看如何把一个jwt通过插件的方式添加到一个请求中I:

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

现在让我们来看下更复杂的例子——有可能我们在创建插件的时候还不能访问到jwt，而且不是所有的请求都需要被认证。我们可以通过扩展`TargetType`协议来提供是否需要认证的信息，并且也使用一个闭包来提供token值 。


```swift
class TokenSource {
  var token: String?
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
    AuthPlugin(tokenClosure: { source.token })
  ]
)

source.token = "eyeAm.AJsoN.weBTOKen"
```
