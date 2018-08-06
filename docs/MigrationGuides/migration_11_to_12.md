# Migration Guide from 11.x to 12.x

This project follows [Semantic Versioning](http://semver.org).

### ReactiveSwift Migration
- Check the [ReactiveSwift 4.0.0 release notes](https://github.com/ReactiveCocoa/ReactiveSwift/releases/tag/4.0.0) for changes related to ReactiveSwift.

### Result Migration
- Check the [Result 4.0.0 release notes](https://github.com/antitypical/Result/releases/tag/4.0.0) for changes related to Result.

### AccessTokenPlugin Migration
- Handle `.custom(String)` case for `AuthorizationType` or add a default case to achive exhaustiveness.
- The `tokenClosure` parameter of the `AccessTokenPlugin` initializer is no longer an `@autoclosure` so you need to wrap the existing value in a closure.

### Response Migration
- The function signature of `Response`'s filter methods has been changed to use a generic argument with constrained to `RangeExpression` where the `RangeExpression.Bound` is
equal to `Int`, instead of providing overloads supporting both `Range` and `ClosedRange`. Account for this change if you rely on the signature explicitly.
