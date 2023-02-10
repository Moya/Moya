# Async/await

Moya provides an optional `async/await` implementation of `MoyaProvider` that
does a few interesting things. Instead of calling the `request()` method and
providing a callback closure to be executed when the request completes, we use
`await`.

```swift
let provider = MoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
AsyncTask {
    let result = await provider.request(.zen) // return type `Result<Response, MoyaError>`
    switch result {
    case let .success(response):
        // do something with the data
    case let .failure(error):
        // handle the error
    }
}
```

`AsyncTask` is a `typealias` for Apple's `Task` mechanism to resolve conflict
with `Moya.Task`. `Moya.Task` is therefore deprecated and renaming to `HTTPTask`;
a future release will obsolete `Moya.Task` and deprecate `AsyncTask` in favor of
`Task`.

You can also use `requestWithProgress` to track progress of your request:

```swift
AsyncTask {
    try await provider.requestWithProgress(SimpleTarget.posts).forEach({ result in
        switch result {
        case let .success(progress):
            if let response = progress.response {
                // do something with response
            } else {
                print("Progress: \(progress.progress)")
            }
        case let .failure(error):
            break
        }
    })
}
```

or you can use a `for in` loop:

```swift
AsyncTask {
    for await progressResponse in await provider.requestWithProgress(SimpleTarget.posts) {
        switch progressResponse {
        case let .success(progress):
            if let response = progress.response {
                // do something with response
            } else {
                print("Progress: \(progress.progress)")
            }
        case let .failure(error):
            print(error.localizedDescription)
        }
    }
}
```

Request with progress uses the `AsyncStream` mechanism, which you can use
functional operations like `.map`, `.filter`, `.flatMap` etc. on.
