# Migration Guides

This project follows [Semantic Versioning](http://semver.org).

Please follow the appropriate guide below when **upgrading to a new major version** of Moya (e.g. 9.0 -> 10.0).

## Upgrade from 9.x to 10.x

### MoyaError Migration
- Add `.parameterEncoding`, `.objectMapping`, `.encodableMapping`, cases to `MoyaError` or a `default` case to achieve exhaustiveness..

### Task Migration
- Add `.requestJSONEncodable` case to `Task` or default case to achieve exhaustiveness.

### Endpoint Migration
- Replace previously default `method` parameter for `Endpoint.init` with `.get`.
- Replace previously default `httpHeaderFields` parameter for `Endpoint.init` with `nil`.
- Replace `urlRequest` with `try? urlRequest()` or use `do/catch` syntax to handle thrown errors..

### NetworkActivityPlugin Migration
- Add `TargetType` as second argument of `NetworkActivityClosure` in `NetworkActivityPlugin` initializer.

----

## Upgrade from 8.x to 9.x

### TargetType Migration
- Move the `parameters` and `parameterEncoding` to the `task` computed property by using the case `.requestParameters(parameters:encoding:)`
- Replace the task type `.request` with either `.requestPlain` (if you have no parameters) or `.requestParameters(parameters:encoding:)`
- There's no `parameters` and `parameterEncoding` on Endpoints any more (e.g. `addingParameters()`), use the new `task` property instead
- To send URL encoded parameters AND body parameters, you can now use the task type `.requestCompositeParameters(bodyParameters:bodyEncoding:urlParameters:)`
- Simplify occurrences of task type `.download(.request(destination))` to `.downloadDestination(destination)`
- Simplify occurrences of task type `.upload(.file(url))` to `.uploadFile(url)`
- Simplify occurrences of task type `.upload(.multipart(data))` to `.uploadMultipart(data)`

### AccessTokenPlugin Migration
- Add `AccessTokenAuthorizable` conformance to `TargetType`'s using the `AccessTokenPlugin`.
- Specificy an `AuthorizationType` of `.bearer` if `shouldAuthorize` is `true` or undefined.

### Reactive MoyaProvider  Migration
- Replace instances of `RxMoyaProvider<Target>` with `MoyaProvider<Target>` and use the `.rx` namespace to access the RxSwift API.
- Replace instances of `ReactiveMoyaProvider<Target>` with `MoyaProvider<Target>` and use the `.reactive` namespace to access the ReactiveSwift API.
- If you subclass a reactive provider, check out this pull request [Eidolon's migration to Moya 9.0.0](https://github.com/artsy/eidolon/pull/669) which covers migration from subclassing to composition. 
