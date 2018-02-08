# Migration Guide from 10.x to 11.x

This project follows [Semantic Versioning](http://semver.org).

### ReactiveSwift Migration
- Check the [ReactiveSwift 3.0.0 release notes](https://github.com/ReactiveCocoa/ReactiveSwift/releases/tag/3.0.0) for changes related to ReactiveSwift.

### Endpoint Migration
- Remove the generic constraint from the `Endpoint` type. Existing code should "just work" after the removal of the generic constraint.

### MoyaProvider Migration
- Replace usage of `MoyaProvider.defaultEndpointMapping` with `MoyaProvider<YourType>.defaultEndpointMapping`, `MoyaProvider.defaultRequestMapping` with `MoyaProvider<YourType>.defaultRequestMapping` and `MoyaProvider.defaultAlamofireManager` with `MoyaProvider<YourType>.defaultAlamofireManager`.

### Task Migration
- Add `.requestCustomJSONEncodable` case to `Task` or default case to achieve exhaustiveness.

### TargetType Migration
- Replace the `validate` property of `TargetType` with the new property `validationType`.
If `validate` was previously `false`, use `ValidationType.none`. If `true`, use `ValidationType.successCodes`. The default is `ValidationType.none`.
