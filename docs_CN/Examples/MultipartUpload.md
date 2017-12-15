# Multipart upload

假设我们想在一个请求中上传GIF的同时附带额外的参数。那么我们如何来解决这个问题? 其实它取决于这个参数是body(e.g. POST, PUT)的一部分，还是是URL的一部分(e.g. GET)。

## 设置

假设我们有一个遵循`TargetType`协议的 `MyService` 服务 :

```swift
public enum MyService {
    case uploadGif(Data, description: String)
}
```

这儿, 我们附加的参数是 `description`, 它是 `String`类型.

## body中的参数

当我们想在一个请求body中完成附加参数的多部分上传请求时，我们必须为每个创建一个`MultipartFormData`对象，然后在 `task`中返回一个`.uploadMultipart(_:)`实例对象 :

```swift
extension MyService: TargetType {
//...
    public var task: Task {
        switch self {
        case let .uploadGif(data, description):
            let gifData = MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
            let descriptionData = MultipartFormData(provider: .data(description.data(using: .utf8)!), name: "description")
            let multipartData = [gifData, descriptionData]

            return .uploadMultipart(multipartData)
        }
    }
//...
}
```

## 在 URL中的参数

在 URL中的附加参数, 我们只需要使用新的 `Task` 类型, `uploadCompositeMultipart(_:urlParameters)`:

```swift
extension MyService: TargetType {
//...
    public var task: Task {
        switch self {
        case let .uploadGif(data, description):
            let gifData = MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
            let multipartData = [gifData]
            let urlParameters = ["description": description]

            return .uploadCompositeMultipart(multipartData, urlParameters: urlParameters)
        }
    }
//...
}
```
