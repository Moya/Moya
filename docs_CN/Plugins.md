# 插件

Moya的插件是被用来编辑请求、响应及完成副作用的。 插件调用:

- (`prepare`)  Moya 已经分解 `TargetType` 成 `URLRequest`之后被执行.
  这是请求被发送前进行编辑的一个机会 (例如 添加
  headers).
- (`willSend`) 请求将要发送前被执行. 这是检查请求和执行任何副作用(如日志)的机会。
- (`didReceive`) 接收到一个响应后被执行. 这是一个检查响应和执行副作用的机会。
- (`process`) 在 `completion` 被调用前执行. 这是对`request`的`Result`进行任意编辑的一个机会。

## 内置插件
Moya附带了一些用于常见功能的默认插件: 身份验证, 网络活动指示器管理 和 日志记录.
您可以在构造provider的时候申明插件来使用它:

```swift
let provider = MoyaProvider<GitHub>(plugins: [NetworkLoggerPlugin(verbose: true)])
```

### 身份验证
身份验证插件允许用户给每个请求赋值一个可选的 `URLCredential` 。当收到请求时，没有操作 

这个插件可以在 [`Sources/Moya/Plugins/CredentialsPlugin.swift`](../Sources/Moya/Plugins/CredentialsPlugin.swift)中找到

### 网络活动指示器
在iOS网络中一个非常常见的任务就是在网络请求是显示一个网络活动指示器，当请求完成时移除它。提供的插件添加了回调，当请求开始和结束时调用，它可以用来跟踪正在进行的请求数，并相应的显示和隐藏网络活动指示器。

这个插件可以在 [`Sources/Moya/Plugins/NetworkActivityPlugin.swift`](../Sources/Moya/Plugins/NetworkActivityPlugin.swift)中找到

### 日志记录
在开发期间，将网络活动记录到控制台是非常有用的。这可以是任何来自发送和接收请求URL的内容，来记录每个请求和响应的完整的header，方法，请求体。

The provided plugin for logging is the most complex of the provided plugins, and can be configured to suit the amount of logging your app (and build type) require. When initializing the plugin, you can choose options for verbosity, whether to log curl commands, and provide functions for outputting data (useful if you are using your own log framework instead of `print`) and formatting data before printing (by default the response will be converted to a String using `String.Encoding.utf8` but if you'd like to convert to pretty-printed JSON for your responses you can pass in a formatter function, see the function `JSONResponseDataFormatter` in [`Demo/Shared/GitHubAPI.swift`](../Demo/Shared/GitHubAPI.swift) for an example that does exactly that)

这个插件可以在 [`Sources/Moya/Plugins/NetworkLoggerPlugin.swift`](../Sources/Moya/Plugins/NetworkLoggerPlugin.swift)中找到

## 自定义插件

Every time you need to execute some pieces of code before a request is sent and/or immediately after a response, you can create a custom plugin, implementing the `PluginType` protocol.
For examples of creating plugins, see [`docs/Examples/CustomPlugin.md`](Examples/CustomPlugin.md) and [`docs/Examples/AuthPlugin.md`](Examples/AuthPlugin.md).
