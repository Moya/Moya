# Migration Guide from 13.x to 14.x

This project follows [Semantic Versioning](http://semver.org).

### NetworkLoggerPlugin Migration
`NetworkLoggerPlugin` have been revamped and a `NetworkLoggerPlugin.Configuration` instance is now needed to instanciate it:
- The `verbose` and `cURL` flag are replaced by the `NetworkLoggerPlugin.Configuration.LogOptions` option set that allows finer tuning of logged elements. Use `.verbose` value to display every possible element and `formatRequestAscURL` to format request's logs as cURL.
- The `output` closure no longer provides a `separator` and `terminator`, and items are now of type `String` instead of `Any`. To provide extra context, the target is also now provided in parameters.
- `requestDataFormatter` and `responseDataFormatter` moved into a new `Configuration.Formatter` object and are now called `requestData` and `responseData`. Their return type have also changed from `Data` to `String`.
