# Migration Guide

This project follows [Semantic Versioning](http://semver.org).

Please follow the appropriate guide below when **upgrading to a new major version** of Moya (e.g. 9.0 -> 10.0).

## Upgrade from 9.x to 10.x

### MoyaError Migration
- Add `.parameterEncoding`, `.objectMapping`, `.encodableMapping`, cases to `MoyaError` or a `default` case to achieve exhaustiveness.

### Task Migration
- Add `.requestJSONEncodable` case to `Task` or default case to achieve exhaustiveness.

### Endpoint Migration
- Replace previously default `method` parameter for `Endpoint.init` with `.get`.
- Replace previously default `httpHeaderFields` parameter for `Endpoint.init` with `nil`.
- Replace `urlRequest` with `try? urlRequest()` or use `do/catch` syntax to handle thrown errors.

### NetworkActivityPlugin Migration
- Add `TargetType` as second argument of `NetworkActivityClosure` in `NetworkActivityPlugin` initializer.
