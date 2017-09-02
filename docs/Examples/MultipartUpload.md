# Multipart upload

Suppose we want to upload a GIF with additional parameters in one request. How to approach this problem? It depends if our parameters should be in body of the request or in the URL.

## Setup

Let's say we have our `TargetType` already setup - it's called `MyService`:

```swift
public enum MyService {
    case uploadGif(Data, description: String)
}
```

Here, our additional parameter is `description`, which is a `String`.

## Parameters in body

When we want to add parameters to the body of our request, we need to append them as a `MultipartFormData` in the `task` property:

```swift
extension MyService: TargetType {
//...
    public var task: Task {
        switch self {
        case let .uploadGif(data, description):
            let gifData = MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
            let descriptionData = MultipartFormData(provider: .data(description.data(using: .utf8)!), name: "description")
            let multipartData = [gifData, descriptionData]

            return uploadMultipart(multipartData)
        default:
            return .requestPlain
        }
    }
//...
}
```