# 身份验证

身份验证变化多样。可以通过一些方法对网络请求进行身份验证。让我们来讨论常见的两种。

## 基本的HTTP身份验证

HTTP身份验证是一个 username/password HTTP协议内置的验证方式. 如果您需要使用 HTTP身份验证, 当初始化provider的时候可以使用一个 `CredentialsPlugin`
。

```swift
let provider = MoyaProvider<YourAPI>(plugins: [CredentialsPlugin { _ -> URLCredential? in
        return URLCredential(user: "user", password: "passwd", persistence: .none)
    }
])
```

这个特定的例子显示了HTTP的使用，它验证 _每个_ 请求,
通常这是不必要的。下面的方式可能更好:

```swift
let provider = MoyaProvider<YourAPI>(plugins: [CredentialsPlugin { target -> URLCredential? in
        switch target {
        case .targetThatNeedsAuthentication:
            return URLCredential(user: "user", password: "passwd", persistence: .none)
        default:
            return nil
        }
    }
])
```

## 访问令牌认证
另一个常见的身份验证方法就是通过使用一个访问令牌。
Moya提供一个 `AccessTokenPlugin` 来完成
 [JWT](https://jwt.io/introduction/)的 `Bearer` 认证 和 `Basic` 认证 。

 开始使用`AccessTokenPlugin`之前需要两个步骤.

1. 您需要把 `AccessTokenPlugin` 添加到您的`MoyaProvider`中，就像下面这样:

```Swift
let token = "eyeAm.AJsoN.weBTOKen"
let authPlugin = AccessTokenPlugin(tokenClosure: token)
let provider = MoyaProvider<YourAPI>(plugins: [authPlugin])
```

`AccessTokenPlugin` 构造器接收一个`tokenClosure`闭包来负责返回一个可以被添加到request头部的令牌 。

2. 您的 `TargetType` 需要遵循`AccessTokenAuthorizable` 协议:

```Swift
extension YourAPI: TargetType, AccessTokenAuthorizable {
    case targetThatNeedsBearerAuth
    case targetThatNeedsBasicAuth
    case targetDoesNotNeedAuth

    var authorizationType: AuthorizationType {
        switch self {
            case .targetThatNeedsBearerAuth:
                return .bearer
            case .targetThatNeedsBasicAuth:
                return .basic
            case .targetDoesNotNeedAuth:
                return .none
            }
        }
}
```

`AccessTokenAuthorizable` 协议需要您实现一个属性 , `authorizationType`, 是一个枚举值，代表用于请求的头

**Bearer HTTP 认证**
Bearer 请求通过向HTTP头部添加下面的表单来获得授权:

```
Authorization: Bearer <token>
```

**Basic API Key 认证**
Basic 请求通过向HTTP头部添加下面的表单来获得授权

```
Authorization: Basic <token>
```

## OAuth

OAuth 有些麻烦。 它涉及一个多步骤的过程，在不同的api之间通常是不同的。 您 _确实_ 不想自己来做OAuth –
这儿有其他的库为您服务. [Heimdallr.swift](https://github.com/rheinfabrik/Heimdallr.swift),
例如. The trick is just getting Moya and whatever you're using to talk
to one another.

Moya内置了OAuth思想。 使用OAuth的网络请求“签名”本身有时会要求执行网络请求，所以对Moya的请求是一个异步的过程。让我们看看一个例子。

```swift
let requestClosure = { (endpoint: Endpoint, done: MoyaProvider.RequestResultClosure) in
    let request = endpoint.urlRequest // This is the request Moya generates
    YourAwesomeOAuthProvider.signRequest(request, completion: { signedRequest in
        // The OAuth provider can make its own network calls to sign your request.
        // However, you *must* call `done()` with the signed so that Moya can
        // actually send it!
        done(.success(signedRequest))
    })
}
let provider = MoyaProvider<YourAPI>(requestClosure: requestClosure)
```

(注意 Swift能推断出您的 `YourAPI` 类型)

## 在您的Provider子类中处理session刷新

您可以查看在每个请求前session刷新的示例[Examples/SubclassingProvider](Examples/SubclassingProvider.md).
它是基于 [Artsy's networking implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/Networking.swift).
