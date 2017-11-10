# Migration Guide from 8.x to 9.x

This project follows [Semantic Versioning](http://semver.org).

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

