# Migration Guide from 11.x to 12.x

This project follows [Semantic Versioning](http://semver.org).

### AccessTokenPlugin Migration

- Handle the `.custom(String)` case for `AuthorizationType` which now allows you add a custom prefix to your authorization token according to the following format: `Authorization: <Custom> <token>`
- The `tokenClosure` parameter of the `AccessTokenPlugin` initializer is no longer an `@autoclosure`, so you need to wrap the existing value in a closure.

### Response Migration

- The function signature of `Response`'s filter methods has been changed to use a generic argument constrained to `RangeExpression` where the `RangeExpression.Bound` is equal to `Int`, instead of providing overloads supporting both `Range` and `ClosedRange`. Account for this change if you rely on the signature explicitly.

### ReactiveSwift Migration

- Check the [ReactiveSwift 4.0.0 release notes](https://github.com/ReactiveCocoa/ReactiveSwift/releases/tag/4.0.0) for changes related to ReactiveSwift.

### Result Migration

- Check the [Result 4.0.0 release notes](https://github.com/antitypical/Result/releases/tag/4.0.0) for changes related to Result.
