# Async/await

Moya provides an optional `Async/await` implementation of
`MoyaProvider` that does a few interesting things. Instead of
calling the `request()` method and providing a callback closure
to be executed when the request completes, we use `await`.

```swift
let provider = MoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
AsyncTask {
    let result = await provider.request(.zen) //return type `Result<Response, MoyaError>`
    switch result {
    case let .success(response):
        // do something with the data
    case let .failure(error):
        // handle the error
    default:
        break
    }
}
```

`AsyncTask` is `typealias` for Apple mechanism `Task` for resolve conflict with `Moya.Task`.

You can also use `requestWithProgress` to track progress of 
your request:
```swift
await provider.requestWithProgress(SimpleTarget.posts).forEach({ result in
    switch result {
    case let .success(progress):
        if let response = progress.response {
            // do something with response
        } else {
            print("Progress: \(progressResponse.progress)")
        }
    case let .failure(error):
        break
    }
})
```

or you can use `for in` loop:

```swift
for await progressResponse in await provider.requestWithProgress(SimpleTarget.posts) {
    case let .success(progress):
        if let response = progress.response {
            // do something with response
        } else {
            print("Progress: \(progressResponse.progress)")
        }
    case let .failure(error):
        break
    }
}
```

Request with progress use `AsyncStream` mechanism you can use with him all functional operations like `.map`, `.filter`, `.flatMap` e.t.c.