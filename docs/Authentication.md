# Authentication

Authentication can be tricky. There are a few ways network requests
can be authenticated. Let's discuss two of the common ones.

## Basic HTTP Auth

HTTP auth is a username/password challenge built into the HTTP protocol
itself. If you need to use HTTP auth, you can provide a `CredentialsPlugin`
when initializing your provider.

```swift
let provider = MoyaProvider<YourAPI>(plugins: [CredentialsPlugin { _ -> URLCredential? in
        return URLCredential(user: "user", password: "passwd", persistence: .none)
    }
])
```

This specific examples shows a use of HTTP that authenticates _every_ request,
which is usually not necessary. This might be a better idea:

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

## Access Token Auth
Another common method of authentication is by using an access token.
Moya provides an `AccessTokenPlugin` that supports both `Bearer` authentication
using a [JWT](https://jwt.io/introduction/) and `Basic` authentication as defined in the [HTTP Authentication Scheme Registry](https://www.iana.org/assignments/http-authschemes/http-authschemes.xhtml). For API keys, it additionally supports passing the API key via a custom header or query parameter.

There are two steps required to start using an `AccessTokenPlugin`.

1. You need to add an `AccessTokenPlugin` to your `MoyaProvider` like this:
```Swift
let tokenClosure = { return "eyeAm.AJsoN.weBTOKen" }
let accessTokenPlugin = AccessTokenPlugin(tokenClosure: tokenClosure)
let provider = MoyaProvider<YourAPI>(plugins: [accessTokenPlugin])
```
The `AccessTokenPlugin` initializer accepts a `tokenClosure` that is responsible
for returning the token to be applied to the header of the request.

2. Your `TargetType` needs to conform to the `AccessControllable` protocol:

```Swift
extension YourAPI: TargetType, AccessControllable {
    case targetDoesNotNeedAuth
    case targetThatNeedsBearerAuth
    case targetThatNeedsBasicAuth
    case targetThatNeedsCustomParameterAuth
    case targetThatNeedsCustomHeaderAuth

    var accessControlType: AccessControlType {
        switch self {
        case .targetDoesNotNeedAuth:
            return .none
        case .targetThatNeedsBearerAuth:
            return .http(scheme: .bearer)
        case .targetThatNeedsBasicAuth:
            return .http(scheme: .basic)
        case .targetThatNeedsCustomParameterAuth:
            return .apiKey(name: "access_token", placement: .queryParameter)
        case .targetThatNeedsCustomHeaderAuth:
            return .apiKey(name: "X-Access-Token", placement: .header)
        }
    }
}
```

The `AccessControllable` protocol requires you to implement a single
property, `accessControlType`, which is an enum representing the type of 
access control that should be used for the request.

**Bearer HTTP Auth**
Bearer requests are authorized by adding a HTTP header of the following form:

```
Authorization: Bearer <token>
```

**Basic API Key Auth**
Basic requests are authorized by adding a HTTP header of the following form:

```
Authorization: Basic <token>
```

## OAuth

OAuth is quite a bit trickier. It involves a multi step process that is often
different between different APIs. You _really_ don't want to do OAuth yourself –
there are other libraries to do it for you. [Heimdallr.swift](https://github.com/rheinfabrik/Heimdallr.swift),
for example. The trick is just getting Moya and whatever you're using to talk
to one another.

Moya is built with OAuth in mind. "Signing" a network request with OAuth can
itself sometimes require network requests be performed _first_, so signing
a request for Moya is an asynchronous process. Let's see an example.

```swift
let requestClosure = { (endpoint: Endpoint<YourAPI>, done: URLRequest -> Void) in
    let request = try! endpoint.urlRequest() // This is the request Moya generates

    YourAwesomeOAuthProvider.signRequest(request, completion: { signedRequest in
        // The OAuth provider can make its own network calls to sign your request.
        // However, you *must* call `done()` with the signed so that Moya can
        // actually send it!
        done(.success(signedRequest))
    })
}
let provider = MoyaProvider<YourAPI>(requestClosure: requestClosure)
```

(Note that Swift is able to infer the `YourAPI` generic – neat!)

## Handle session refresh in your Provider subclass

You can take a look at example of session refreshing before each request in [Examples/SubclassingProvider](Examples/SubclassingProvider.md).
It is based on [Artsy's networking implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/Networking.swift).
