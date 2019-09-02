# Migration Guide from 13.x to 14.x

This project follows [Semantic Versioning](http://semver.org).

### NetworkLoggerPlugin Migration
`NetworkLoggerPlugin` have been revamped and a `NetworkLoggerPlugin.Configuration` instance is now needed to instanciate it:
- The `verbose` flag is replaced by the `NetworkLoggerPlugin.Configuration.LogOptions` option set that allows finer tuning of logged elements. Use the value  `.verbose` to display every possible element.
- The `output` closure no longer provides a `separator` and `terminator`, and items are now of type `String` instead of `Any`. To provide extra context, the target is also now provided in parameters.
- `responseDataFormatter` now returns `String` instead of `Data`.
