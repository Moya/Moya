RxSwift
=======

Moya provides an optional `RxMoyaProvider` subclass of
`MoyaProvider` that does a few interesting things. Instead of
calling the `request()` method and providing a callback closure
to be executed when the request completes, we use `Observable`s.

A `RxMoyaProvider` can be created much like a
[`MoyaProvider`](Providers.md) and can be used as follows:

```swift
let provider = RxMoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
provider.request(.zen).subscribe { event in
    switch event {
    case .next(let response):
        // do something with the data
    case .error(let error):
        // handle the error
    default:
        break
    }
}
```

For `RxMoyaProvider`, the network request is not started
until the signal is subscribed to. If the subscription to the signal
is disposed of before the request completes, the request is cancelled.

If the request completes normally, two things happen:

1. The observable sends a value, a `Moya.Response` instance.
2. The observable completes.

If the request produces an error (typically a `URLSession` error),
then it sends an error, instead. The error's `code` is the failing
request's status code, if any, and the response data, if any.

The `Moya.Response` class contains a `statusCode`, some `data`,
and a(n optional) `URLResponse`. You can use these values however
you like in `subscribeNext` or `map` calls.

To make things even awesomer, Moya provides some extensions to
`Observable` that make dealing with `MoyaResponses`really easy.

- `filter(statusCodes:)` takes a range of status codes. If the
  response's status code is not within that range, an error is
  produced.
- `filter(statusCode:)` looks for a specific status code, and errors
  if it finds anything else.
- `filterSuccessfulStatusCodes()` filters status codes that
  are in the 200-range.
- `filterSuccessfulStatusAndRedirectCodes()` filters status codes
  that are in the 200-300 range.
- `mapImage()` tries to map the response data to a `UIImage` instance
  and errors if unsuccessful.
- `mapJSON()` tries to map the response data to a JSON object and
  errors if unsuccessful.
- `mapString()` tries to map the response data to a string and
  errors if unsuccessful.
- `mapString(atKeyPath:)` tries to map a response data key path to a string and
  errors if unsuccessful.

In the error cases, the error's `domain` is `MoyaErrorDomain`. The code
is one of `MoyaErrorCode`'s `rawValue`s, where appropriate. Wherever
possible, underlying errors are provided and the original response
data is included in the `NSError`'s `userInfo` dictionary using the
"data" key.
