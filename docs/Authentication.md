Authentication
==============

Authentication can be tricky. There are a few ways network requests
can be authenticated. Let's discuss two of the common ones.

Basic HTTP Auth
---------------

HTTP auth is a username/password challenge built into the HTTP protocol
itself. If you need to use HTTP auth, you can provide a `CredentialsPlugin`
when initializeing your provider. 

```swift
let provider = MoyaProvider<YourAPI>(plugins: [CredentialsPlugin { _ -> NSURLCredential? in
    return NSURLCredential(user: "user", password: "passwd", persistence: .None)
  }
])
```

This specific examples shows a use of HTTP that authenticates _every_ request, 
which is usually not necessary. This might be a better idea:

```swift
let provider = MoyaProvider<YourAPI>(plugins: [CredentialsPlugin { target -> NSURLCredential? in
    switch target {
      case .TargetThatNeedsAuthentication:
        return NSURLCredential(user: "user", password: "passwd", persistence: .None)
      default:
        return nil
    }
  }
])
```

OAuth
-----

OAuth is quite a bit trickier. It involes a multistep process that is often 
different between different APIs. You _really_ don't want to do OAuth yourself –
there are other libraries to do it for you. [Heimdall.swift](https://github.com/rheinfabrik/Heimdall.swift),
for example. The trick is just getting Moya and whatever you're using to talk
to one another. 

Moya is built with OAuth in mind. "Signing" a network request with OAuth can
itself sometimes require network requests be performed _first_, so signing
a request for Moya is an asynchronous process. Let's see an example. 

```swift
let requestClosure = { (endpoint: Endpoint<YourAPI>, done: NSURLRequest -> Void) in
    let request = endpoint.urlRequest // This is the request Moya generates
    YourAwesomeOAuthProvider.signRequest(request, completion: { signedRequest in
      // The OAuth provider can make its own network calls to sign your request.
      // However, you *must* call `done()` with the signed so that Moya can
      // actually send it!
      done(signedRequest)
    })
}
let provider = MoyaProvider(requestClosure: requestClosure)
```

(Note that Swift is able to infer the `YourAPI` generic – neat!)
