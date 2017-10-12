# Migration Guide from 9.x to 10.x

This project follows [Semantic Versioning](http://semver.org).

### MoyaError Migration
- Add `.parameterEncoding`, `.objectMapping`, `.encodableMapping`, cases to `MoyaError` or a `default` case to achieve exhaustiveness.

### Task Migration
- Add `.requestJSONEncodable` case to `Task` or default case to achieve exhaustiveness.

### Endpoint Migration
- Replace previously default `method` parameter for `Endpoint.init` with `.get`.
- Replace previously default `httpHeaderFields` parameter for `Endpoint.init` with `nil`.
- Replace `Endpoint`'s `urlRequest` property with the throwing method `try? urlRequest()` or use `do/catch` syntax to handle thrown errors.

### NetworkActivityPlugin Migration
- Add `TargetType` as second argument of `NetworkActivityClosure` in `NetworkActivityPlugin` initializer.

### ReactiveCocoa subspec Migration
- Replace `pod 'Moya/ReactiveCocoa'` with `pod 'Moya/ReactiveSwift'` in your Podfile.
