# Testing

Moya has been created with testing at its heart. In this document, you will find all the customization points that will allow you to tailor your testing.

## `sampleData`

When creating your `TargetType` you are required to provide `sampleData` for your targets. All you need to do there is to provide `Data` that represents a sample response from every particular target.

For example:

```swift
public var sampleData: Data {
    switch self {
    case .userRepositories(let name):
        return "[{\"name\": \"Repo Name\"}]".data(using: String.Encoding.utf8)!
    }
}
```

This can be used later for tests or just for providing offline support while developing.

## `stubClosure`

Sample data is not meant to be the default response for your calls. This substitution will not happen without configuring your provider for stubbing:

```swift
let stubbingProvider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub)
```

With that definition, your requests are going to receive *immediate* responses with your `sampleData`.

You can also use the `MoyaProvider.delayedStub(:)`. This will allow you to delay the stubbed responses to simulate the delays the real network calls may have. Further, you can also implement your own `StubClosure`. It will allow you to define the stubbing behavior target by target (and/or any condition related to the targets that you may have).

Before you continue, it is worth mentioning that all the sample responses will be delivered with an HTTP status `200` by default.

## `sampleResponseClosure`

With the previous `sampleData` and `stubClosure`, we could only specify the data returned when stubbing. But you have more options.

Moya offers you the opportunity to configure an [`endpointClosure`](https://github.com/Moya/Moya/blob/master/docs/Endpoints.md#from-target-to-endpoint) on your provider. In that closure, you convert from `Target` to `Endpoint`. And this `Endpoint` is where you are going to be able to specify more details for your testing. More concretely, on its `sampleResponseClosure`.

As we discussed above, the default stubbing behavior is to respond to requests with your sample data with a `200` HTTP status code. This is, because the default `endpointClosure` defines a default `sampleResponseClosure` as follows:

```swift
{ .networkResponse(200, target.sampleData) }
```

A `sampleResponseClosure` should return a `EndpointSampleResponse`, an it can be:

- A `.networkResponse(Int, Data)` where `Int` is a status code and `Data` is the returned data.
 Useful to customize either response codes or data to your own specification.
- A `.response(HTTPURLResponse, Data)` where `HTTPURLResponse` is the response and `Data` is the returned data.
 Useful to *fully* stub your responses.
- A `.networkError(NSError)` where `NSError` is the error occurred when sending the request or retrieving a response.
 Useful to test for any network errors: Timeouts, reachability issues, etc.

For example, the following code creates a provider to stub with *immediate* `401` responses:

```swift
let customEndpointClosure = { (target: APIService) -> Endpoint<APIService> in
    return Endpoint(url: URL(target: target).absoluteString,
                    sampleResponseClosure: { .networkResponse(401 , /* data relevant to the auth error */) },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers)
}

let stubbingProvider = MoyaProvider<GitHub>(endpointClosure: customEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
```
