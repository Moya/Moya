Plugins
=======

Moya plugins are used to modify requests and responses or perform side-effects.
A plugin is called:
- (`prepare`) after Moya has resolved the `TargetType` to a `URLRequest`.
  This is an opportunity to modify the request before it is sent (e.g. add
  headers).
- (`willSend`) before a request is about to be sent. This is an
  opportunity to inspect the request and perform any side-effects (e.g. logging).
- (`didReceive`) after a response has been received. This is an
  opportunity to inspect the response and perform side-effects.
- (`process`) before `completion` is called with the `Result`. This is
  an opportunity to make any modifications to the `Result` of the `request`.

## Built in plugins
Moya ships with some default plugins which can be used for common functions: authentication, network activity indicator management and logging.
You can use a plugin simply declaring it during the initialization of the provider:

```swift
let provider = MoyaProvider<GitHub>(plugins: [NetworkLoggerPlugin(verbose: true)])
```

#### Authentication
The authentication plugin allows a user to assign an optional `URLCredential` per request. There is no action when a request is received.

The plugin can be found at [`Sources/Moya/Plugins/CredentialsPlugin.swift`](../Sources/Moya/Plugins/CredentialsPlugin.swift)

#### Network Activity Indicator
One very common task with iOS networking is to show a network activity indicator during network requests, and remove it when all requests have finished. The provided plugin adds callbacks which are called when a requests starts and finishes, which can be used to keep track of the number of requests in progress, and show / hide the network activity indicator accordingly.

The plugin can be found at [`Sources/Moya/Plugins/NetworkActivityPlugin.swift`](../Sources/Moya/Plugins/NetworkActivityPlugin.swift)

#### Logging
During development it can be very useful to log network activity to the console. This can be anything from the URL of a request as sent and received, to logging full headers, method, request body on each request and response.

The provided plugin for logging is the most complex of the provided plugins, and can be configured to suit the amount of logging your app (and build type) require. When initializing the plugin, you can choose options for verbosity, whether to log curl commands, and provide functions for outputting data (useful if you are using your own log framework instead of `print`) and formatting data before printing (by default the response will be converted to a String using `String.Encoding.utf8` but if you'd like to convert to pretty-printed JSON for your responses you can pass in a formatter function, see the function `JSONResponseDataFormatter` in [`Demo/Shared/GitHubAPI.swift`](../Demo/Shared/GitHubAPI.swift) for an example that does exactly that)

The plugin can be found at [`Sources/Moya/Plugins/NetworkLoggerPlugin.swift`](../Sources/Moya/Plugins/NetworkLoggerPlugin.swift)

## Custom plugins

Every time you need to execute some pieces of code before a request is sent and/or immediately after a response, you can create a custom plugin, implementing the `PluginType` protocol.
For examples of creating plugins, see [`docs/Examples/CustomPlugin.md`](Examples/CustomPlugin.md) and [`docs/Examples/AuthPlugin.md`](Examples/AuthPlugin.md).
