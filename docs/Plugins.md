Plugins
=======

Moya plugins are used to perform some side effect whenever a request is sent or received. Plugins are defined by the `PluginType` protocol, which can receive callbacks when:
- a request is going to be sent;
- a response has been received.

##Built in plugins
Moya ships with some default plugins which can be used for common functions: authentication, network activity indicator management and logging.
You can use a plugin simply declaring it during the initialization of the provider:

```swift
let provider = MoyaProvider<GitHub>(plugins: [NetworkLoggerPlugin(verbose: true)])
```

####Authentication
The authentication plugin allows a user to assign an optional `NSURLCredential` per request. There is no action when a request is received.

The plugin can be found at [`Source/Plugins/CredentialsPlugin.swift`](../Source/Plugins/CredentialsPlugin.swift)

####Network Activity Indicator
One very common task with iOS networking is to show a network activity indicator during network requests, and remove it when all requests have finished. The provided plugin adds callbacks which are called when a requests starts and finishes, which can be used to keep track of the number of requests in progress, and show / hide the network activity indicator accordingly.

The plugin can be found at [`Source/Plugins/NetworkActivityPlugin.swift`](../Source/Plugins/NetworkActivityPlugin.swift)

####Logging
During development it can be very useful to log network activity to the console. This can be anything from the URL of a request as sent and received, to logging full headers, method, request body on each request and response.

The provided plugin for logging is the most complex of the provided plugins, and can be configured to suit the amount of logging your app (and build type) require. When initializing the plugin, you can choose options for verbosity, whether to log curl commands, and provide functions for outputting data (useful if you are using your own log framework instead of `print`) and formatting data before printing (by default the response will be converted to a String using `NSUTF8StringEncoding` but if you'd like to convert to pretty-printed JSON for your responses you can pass in a formatter function, see the function `JSONResponseDataFormatter` in [`Demo/Demo/GitHubAPI.swift`](../Demo/Demo/GitHubAPI.swift) for an example that does exactly that)

The plugin can be found at [`Source/Plugins/NetworkLoggerPlugin.swift`](../Source/Plugins/NetworkLoggerPlugin.swift)

##Custom plugins

Every time you need to execute some pieces of code before a request is sent and/or immediately after a response, you can create a custom plugin, implementing the `PluginType` protocol.
For an example of creating a new plugin, see [`docs/Examples/CustomPlugin.md`](Examples/CustomPlugin.md)
