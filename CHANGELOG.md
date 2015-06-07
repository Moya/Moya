# 1.1.0

- Adds support for RxSwift – [@alcarvalho](http://github.com/alcarvalho)

# 1.0.0

-  **Breaking change** Changes `EndpointSampleResponse` to require closures that return `NSData`, not `NSData` instances themselves. This prevents sample data from being loaded during the normal, non-unit test app lifecycle.
- **Breaking change** Adds `method` to `MoyaTarget` protocol and removes `method` parameter from `request()` functions. Targets now specify GET, POST, etc on a per-target level, instead of per-request.
- **Breaking change** Adds `parameters` to `MoyaTarget` protocol and removes ability to pass parameters into `request()` functions. Targets now specify the parameters directly on a per-target level, instead of per-request.
- Adds a sane default implementation of the `MoyaProvider` initializer's `endpointsClosure` parameter.

# 0.8.0

- Updates to Swift 1.2.

# 0.7.1

- Adds cancellable requests -[@MichaelMcGuire](http://github.com/MichaelMcGuire)

# 0.7.0

- Adds network activity closure to provider.

# 0.6.1

- Updates podspec to refer to `3.0.0-aplha.1` of ReactiveCocoa. -[@ashfurrow](http://github.com/ashfurrow)

# 0.6

- First release on CocoaPods trunk.
- Add data support for [stubbed error responses](https://github.com/ashfurrow/Moya/pull/92). – [@steam](http://github.com.steam)
- Fixes [#66](https://github.com/AshFurrow/Moya/issues/66), a problem with outdated Alamofire dependency and it's serializer type signature. -[@garnett](http://github.com/garnett)
- Delete note about ReactiveCocoa installation -[@garnett](http://github.com/garnett)

# 0.5

- Fixes [#52](https://github.com/AshFurrow/Moya/issues/52) to change submodules to use http instead of ssh. -[@ashfurrow)](http://github.com/AshFurrow)
- Migrate to support Xcode beta 6.1 -[@orta)](http://github.com/orta)
- Adds the original NSURLResponse to a MoyaResponse -[@orta)](http://github.com/orta)
- Fixes [#63](https://github.com/AshFurrow/Moya/issues/63), a problem where stale inflight requests were kept around if they error'd down the pipline (discussed [here](https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1525#issuecomment-58559734)) -[@ashfurrow](http://github.com/AshFurrow)

# 0.4

- Implements [#46](https://github.com/AshFurrow/Moya/issues/46), the code property of the NSError sent through by ReactiveMoyaProvider will now match the failing http status code. -[@powerje](http://github.com/powerje)

# 0.3

- Fixes [#48](https://github.com/AshFurrow/Moya/issues/48) that modifies Moya to execute completion blocks of stubbed responses *immediately*, instead of using `dispatch_async` to defer it to the next invocation of the run loop. **This is a breaking change**. Because of this change, the ReactiveCocoa extensions had to be modified slightly to deduplicate inflight stubbed requests. Reactive providers now vend `RACSignal` instances that start the network request *when subscribed to*. -[@ashfurrow](http://github.com/AshFurrow)

# 0.2

- Fixes [#44](https://github.com/AshFurrow/Moya/issues/44) where status codes weren't being pass through to completion blocks. This also modified the behaviour of the ReactiveCocoa extensions significantly but sending MoyaResponse objects instead of just NSData ones. —[@ashfurrow](http://github.com/AshFurrow)

# 0.1

- Initial release.
