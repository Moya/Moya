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
