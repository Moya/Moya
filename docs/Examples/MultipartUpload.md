# Multipart upload

Suppose we want to upload a GIF with additional parameters in one request. How do we approach this problem? It depends if the parameters should be part of the body (e.g. POST, PUT), or part of the URL (e.g. GET).

## Setup

Let's say we have a `MyService` service conforming to `TargetType`:

```swift
public enum MyService {
    case uploadGif(Data, description: String)
}
```

Here, our additional parameter is `description`, which is a `String`.

## Parameters in body

When we want to perform a multipart upload request with additional parameters in the request body, we have to create a `MultipartFormData` for each of our parts and then return a `.uploadMultipartFormData(_:)` in the `task` property:

```swift
extension MyService: TargetType {
//...
    public var task: Task {
        switch self {
        case let .uploadGif(data, description):
            let gifData = MultipartFormBodyPart(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
            let descriptionData = MultipartFormBodyPart(provider: .data(description.data(using: .utf8)!), name: "description")
            let multipartData: MultipartFormData = [gifData, descriptionData]
            // Or if you want to specify the boundary and file manager:
            // let multipartData = MultipartFormData(fileManager: .default, boundary: "...", parts: [gifData, descriptionData])

            return .uploadMultipartFormData(multipartData)
        }
    }
//...
}
```

## Parameters in URL

In case of parameters in URL, we can just use our new `Task` type, `uploadCompositeMultipartFormData(_:urlParameters)`:

```swift
extension MyService: TargetType {
//...
    public var task: Task {
        switch self {
        case let .uploadGif(data, description):
            let gifData = MultipartFormBodyPart(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
            let multipartData: MultipartFormData = [gifData]
            // Or if you want to specify the boundary and file manager:
            // let multipartData = MultipartFormData(fileManager: .default, boundary: "...", parts: [gifData])
            
            let urlParameters = ["description": description]

            return .uploadCompositeMultipartFormData(multipartData, urlParameters: urlParameters)
        }
    }
//...
}
```
