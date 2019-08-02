# Testing

Moya has been created with testing at its heart. In this document, you will find all the customization points that will allow you to tailor your testing.

## `sampleData`

When creating your `TargetType` you are required to provide `sampleData` for your targets. All you need to do there is to provide `Data` that represents a sample response from every particular target. This can be used later for tests or just for providing offline support while developing. 

For example:

```swift
public var sampleData: Data {
    switch self {
    case .userRepositories(let name):
        return "[{\"name\": \"Repo Name\"}]".data(using: String.Encoding.utf8)!
    }
}
```

## `stubClosure`

The `stubClosure` property of a `MoyaProvider` is responsible for configuring whether a provider returns an actual or a stubbed response. This configuration is made in this closure by mapping a `TargetType` to a case of the `StubBehavior` enum:

- `.never` to not stub responses.
- `.immediate` to stub responses immediately.
- `.delayed(seconds: TimeInterval)` to stub responses after a given delay (to simulate the delays the real network calls may have).

For your convenience, `MoyaProvider` defines the `.immediatelyStub` and `.delayedStub(:)` closures that you can set while initializing your provider to always stub responses immediately or with a given delay. For example, in the following provider *all* your requests are going to receive *immediate* responses with your `sampleData`. 

```swift
let stubbingProvider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub)
```

Before you continue, it is worth mentioning that all the stubbed responses will be delivered with an HTTP status `200` by default.

## `sampleResponseClosure`

With the previous `sampleData` and `stubClosure`, we could only specify the data returned when stubbing. But you have more options.

Moya offers you the opportunity to configure an `endpointClosure` on your provider. In this closure, your `Target` needs to be mapped to an `Endpoint`. `Endpoint` is a semi-internal data structure used by Moya to reason about the request. And in this `Endpoint` is where you are going to be able to specify more details for your testing. More concretely, on its `sampleResponseClosure`.

As we discussed above, the default stubbing behavior is to respond to requests with your sample data with a `200` HTTP status code. This is because the default `endpointClosure` defines its `sampleResponseClosure` as follows:

```swift
{ .networkResponse(200, target.sampleData) }
```

If you need to setup your own `sampleResponseClosure`, your implementation should return a case of the `EndpointSampleResponse` enum:

- A `.networkResponse(Int, Data)` where `Int` is a status code and `Data` is the returned data.
 Useful to customize either response codes or data to your own specification.
- A `.response(HTTPURLResponse, Data)` where `HTTPURLResponse` is the response and `Data` is the returned data.
 Useful to *fully* stub your responses.
- A `.networkError(NSError)` where `NSError` is the error that occurred when sending the request or retrieving a response.
 Useful to test for any network errors: Timeouts, reachability issues, etc.

For example, the following code creates a provider to stub with *immediate* `401` responses:

```swift
let customEndpointClosure = { (target: APIService) -> Endpoint in
    return Endpoint(url: URL(target: target).absoluteString,
                    sampleResponseClosure: { .networkResponse(401 , /* data relevant to the auth error */) },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers)
}

let stubbingProvider = MoyaProvider<GitHub>(endpointClosure: customEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
```
