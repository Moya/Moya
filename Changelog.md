# Next

# [15.0.0] - 2021-09-04

### Added
- Added `NetworkLoggerPlugin.default` and `NetworkLoggerPlugin.verbose` to conveniently access the default plugins. [#2095](https://github.com/Moya/Moya/pull/2095) by [@sunshinejr](https://github.com/sunshinejr).

### Changed
- **Breaking Change** Changed `Hashable` && `Equatable` implementation of `Endpoint` since it was returning false positives. [#2101](https://github.com/Moya/Moya/pull/2101) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** `MultiPartFormData` is now `Hashable`. [#2101](https://github.com/Moya/Moya/pull/2101) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** `AccessTokenPlugin` now uses `TargetType`, instead of `AuthorizationType`, in the closure to determine the token. Full `MultiTarget` integration added as well. [#2046](https://github.com/Moya/Moya/pull/2046) by [@Coder-ZJQ](https://github.com/Coder-ZJQ).
- `Target.sampleData` is now automatically implemented as `Data()` with default protocol extension. [#2015](https://github.com/Moya/Moya/pull/2015) by [jdisho](https://github.com/jdisho).
- **Breaking Change** Minimum version of `RxSwift` is now 6.0. [#2120](https://github.com/Moya/Moya/pull/2120) by [@peagasilva](https://github.com/peagasilva).
- Moya's Swift minimum version is now Swift 5.2. [#2120](https://github.com/Moya/Moya/pull/2120) by [@peagasilva](https://github.com/peagasilva).
- Moya now depends on the latest versions of RxSwift, ReactiveSwift & Alamofire. [#2197](https://github.com/Moya/Moya/pull/2197) by [@BasThomas](https://github.com/BasThomas).

### Fixed
- Fixed an issue where when using `trackInflights` option in certain circumstances would return a cached response for an endpoint that's not really the same. [#2101](https://github.com/Moya/Moya/pull/2101) by [@sunshinejr](https://github.com/sunshinejr).
- Fixed a crash where Combine Publisher would crash when using stubs.  [#2072](https://github.com/Moya/Moya/pull/2072) by [jshier](https://github.com/jshier).
- Fixed Unit Tests and CI. [#2187](https://github.com/Moya/Moya/pull/2187) by [OhKanghoon](https://github.com/OhKanghoon).
- Fixed a race condition that could prevent plugin's `willSend(_:target:)` from being fired. [#2192](https://github.com/Moya/Moya/pull/2192) by [anton-plebanovich](https://github.com/anton-plebanovich).

# [15.0.0-alpha.1] - 2020-07-07

### Added
- We brought back Combine support! [#2024](https://github.com/Moya/Moya/pull/2024) by [@MaxDesiatov](https://github.com/MaxDesiatov).

### Changed
- Moya's Swift minimum version is now Swift 5.1. [#1931](https://github.com/Moya/Moya/pull/1931) by [@BasThomas](https://github.com/BasThomas) and [@LucianoPAlmeida](https://github.com/LucianoPAlmeida).

# [14.0.0] - 2020-02-15

### Changed
- **Breaking Change** Minimum version of `Alamofire` is now 5.0. [#1992](https://github.com/Moya/Moya/pull/1992) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** `MultiTarget` now implements `AccessTokenAuthorizable` so that the inner target's `authorizationType` is correctly returned to the `AccessTokenPlugin` when requested. [#1979](https://github.com/Moya/Moya/pull/1979) by [@amaurydavid](https://github.com/amaurydavid).


# [14.0.0-beta.6] - 2019-12-09

### Changed
- **Breaking Change** In `AccessTokenPlugin`, the token closure now takes a `AuthorizationType` as parameter and `AuthorizationType.none` has been removed in favor of using  `AuthorizationType?`. [#1969](https://github.com/Moya/Moya/pull/1969) by [@amaurydavid](https://github.com/amaurydavid).

### Fixed
- Fixed a data race condition issue and enable TSAN on the test action and CI. [#1952](https://github.com/Moya/Moya/pull/1952) by [@LucianoPAlmeida](https://github.com/LucianoPAlmeida).

# [14.0.0-beta.5] - 2019-10-27

### Changed
- **Breaking Change** Minimum version of `Alamofire` is now 5.0.0-rc.3. [#1944](https://github.com/Moya/Moya/pull/1944) by [@sunshinejr](https://github.com/sunshinejr).

# [14.0.0-beta.4] - 2019-10-05

### Removed
- **Breaking Change** Removed Combine extensions for now. Due to problems with weak-linking the framework, it's too difficult to support it with ease using all package managers and also without breaking backwards-compatibility. Probably gonna introduce it once we only support Xcode 11. [#1933](https://github.com/Moya/Moya/pull/1933) by [@sunshinejr](https://github.com/sunshinejr)

# [14.0.0-beta.3] - 2019-09-27

### Fixed
- Fixed an issue with displaying cURL-formatted request in `NetworkLoggerPlugin`. [#1916](https://github.com/Moya/Moya/pull/1916) by [@sunshinejr](https://github.com/sunshinejr).
- Fixed an issue that wouldn't display stubbed response body in `NetworkLoggerPlugin`. [#1916](https://github.com/Moya/Moya/pull/1916) by [@sunshinejr](https://github.com/sunshinejr).
- Fixed an issue where Carthage users using Xcode 11 couldn't install Moya 14. We added weak-linking for the xcodeproj so you might need additional steps for Xcode 10 + Carthage + Moya 14.* users. [#1920](https://github.com/Moya/Moya/pull/1920) by [@fredpi](https://github.com/fredpi) and [@sunshinejr](https://github.com/sunshinejr).
- Fixed an issue that wouldn't persist `URLRequest` changes (created by plugins) when stubbed. [#1921](https://github.com/Moya/Moya/pull/1921) by [@sunshinejr](https://github.com/sunshinejr).
- Fixed an issue with SPM integration - it no longer fetches testing libraries and also doesn't create runtime/Xcode Preview crashes. [#1923](https://github.com/Moya/Moya/pull/1923) by [@sunshinejr](https://github.com/sunshinejr).

# [14.0.0-beta.2] - 2019-09-09

### Changed
- **Breaking Change** Minimum version of `Alamofire` is now 5.0.0-rc.2. [#1912](https://github.com/Moya/Moya/pull/1912) by [@sunshinejr](https://github.com/sunshinejr).

## Added
- Combine support! [#1904](https://github.com/Moya/Moya/pull/1904) by [@sunshinejr](https://github.com/sunshinejr).
- Very raw SPM testing support! Thanks to the work on OHHTTPStubs, we can finally start using `swift test` again. [#1896](https://github.com/Moya/Moya/pull/1896) by [@sunshinejr](https://github.com/sunshinejr).

### Changed
- **Breaking Change** Minimum version of `Alamofire` is now 5.0.0-rc.1. [#1909](https://github.com/Moya/Moya/pull/1909) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** The NetworkLoggerPlugin have been reworked to allow more customization about the logged request's components. [#1894](https://github.com/Moya/Moya/pull/1894) by [@amaurydavid](https://github.com/amaurydavid).
- **Breaking Change** Bumped ReactiveSwift version to 6.1.0. This should only affect Carthage users, but you'll probably want to use 6.1.0 in all of your Xcode 11 projects. [#1896](https://github.com/Moya/Moya/pull/1896) by [@sunshinejr](https://github.com/sunshinejr).
- `NetworkLoggerPlugin` now logs error when available (using `LogOptions.verbose` or specyfing `errorResponseBody` in your `LogOptions`). [#1880](https://github.com/Moya/Moya/pull/1880) by [@amaurydavid](https://github.com/amaurydavid).

# [14.0.0-alpha.2] - 2019-08-01

## Added
- `RequestType` now has `sessionHeaders`! These are the headers that are added when the request is added to a session. [#1878](https://github.com/Moya/Moya/pull/1878) by [@sunshinejr](https://github.com/sunshinejr).

### Changed
- **Breaking Change** Minimum target version are now in line with Alamofire 5. iOS: 10.0, tvOS: 10.0, macOS: 10.12, watchOS: 3.0. [#1810](https://github.com/Moya/Moya/pull/1810) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** Minimum version of `Alamofire` is now 5.0.0-beta.7. [#1810](https://github.com/Moya/Moya/pull/1810) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** Removed `Result` depndency in favor of `Result` introduced in Swift 5. [#1858](https://github.com/Moya/Moya/pull/1858) by [@larryonoff](https://github.com/larryonoff).
- **Breaking Change** Added `TargetType` parameter in the output of `NetworkLoggerPlugin`. [#1866](https://github.com/Moya/Moya/pull/1866) by [@hasankose](https://github.com/hasankose).
- `NetworkLoggerPlugin` uses the newly added `sessionHeaders` and now logs all the headers that the request will produce. [#1878](https://github.com/Moya/Moya/pull/1878) by [@sunshinejr](https://github.com/sunshinejr).

# [14.0.0-alpha.1] - 2019-05-14

### Changed
- **Breaking Change** Minimum version of `RxSwift` is now 5.0. [#1846](https://github.com/Moya/Moya/pull/1846) by [@LucianoPAlmeida](https://github.com/LucianoPAlmeida).
- **Breaking Change** Minimum version of `ReactiveSwift` is now 6.0. [#1849](https://github.com/Moya/Moya/pull/1849) by [@sunshinejr](https://github.com/sunshinejr).``

# [13.0.1] - 2019-05-01

### Fixed
- Fixed a problem where, while using stubbed responses, Moya would generate weird cancellation errors in the console. [#1841](https://github.com/Moya/Moya/pull/1841) by [@sunshinejr](https://github.com/sunshinejr).

# [13.0.0] - 2019-04-10

# [13.0.0-beta.1] - 2019-03-31

### Changed
- **Breaking Change** `.mapImage()` extension on `Single` and `Observable` now returns non-optional image. [#1789](https://github.com/Moya/Moya/pull/1789), [#1799](https://github.com/Moya/Moya/pull/1799) by [@bjarkehs](https://github.com/bjarkehs) and [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** Minimum version of `ReactiveSwift` is now 5.0. [#1817](https://github.com/Moya/Moya/pull/1817) by [@larryonoff](https://github.com/larryonoff).
- **Breaking Change** Minimum version of `Result` is now 4.1. [#1817](https://github.com/Moya/Moya/pull/1817) by [@larryonoff](https://github.com/larryonoff).
- **Breaking Change** Updated project to Swift 5.0. [#1827](https://github.com/Moya/Moya/pull/1827) by [@sunshinejr](https://github.com/sunshinejr).
- Updated project to support Xcode 10.2. [#1826](https://github.com/Moya/Moya/pull/1826) by [@larsschwegmann](https://github.com/larsschwegmann).
- `MoyaError` now conforms to `CustomNSError` protocol, makes underlying errors available in its user-info dictionary. [#1783](https://github.com/Moya/Moya/pull/1783) by [@dpoggi](https://github.com/dpoggi).

### Fixed
- Fixed `Progress` object on responses that did not specify correct `Content-Length` header. Now, whenever there is no valid header, the progress will be 0.0 until the completion of the request. Also, the `completed` property is now `true` only when the response was serialized, we do not rely on progress being 1.0 anymore. [#1815](https://github.com/Moya/Moya/pull/1815) by [@sunshinejr](https://github.com/sunshinejr).

### Removed
- **Breaking change** Removed `validate` on `TargetType`. It was deprecated in Moya 11, use `validationType` instead. [#1828](https://github.com/Moya/Moya/pull/1828) by [@sunshinejr](https://github.com/sunshinejr).

# [12.0.1] - 2018-11-19

# [12.0.0] - 2018-11-18

### Changed
- **Breaking Change** Minimum watchOS deployment target for Moya is now 3.0. [#1758](https://github.com/Moya/Moya/pull/1769) by [@SD10](https://github.com/SD10).
- Fix warnings generated by Xcode 10. Updated project to Swift 4.2 [#1740](https://github.com/Moya/Moya/pull/1740) by [@lexorus](https://github.com/lexorus)

# [12.0.0-beta.1] - 2018-08-07

### Added
- **Breaking Change** Added `.custom(String)` authorization case to `AuthorizationType` inside `AccessTokenPlugin`. [#1611](https://github.com/Moya/Moya/pull/1611) by [@SeRG1k17](https://github.com/SeRG1k17).

### Changed
- **Breaking Change** Minimum version of `ReactiveSwift` is now 4.0. [#1668](https://github.com/Moya/Moya/pull/1668) by [@sunshinejr](https://github.com/sunshinejr).

- **Breaking Change** Minimum version of `Result` is now 4.0. [#1668](https://github.com/Moya/Moya/pull/1668) by [@sunshinejr](https://github.com/sunshinejr).

- **Breaking Change** Changed `Response`s filter method parameter to use a generic `RangeExpression` that accepts any range type. [#1624](https://github.com/Moya/Moya/pull/1624) by [@LucianoPAlmeida](https://github.com/LucianoPAlmeida).

- **Breaking Change** Changed `AccessTokenPlugin`'s initializer to no longer use an `@autoclosure` for the `tokenClosure` parameter. [#1611](https://github.com/Moya/Moya/pull/1611) by [@SeRG1k17](https://github.com/SeRG1k17).

# [11.0.2] - 2018-04-01
### Fixed
- Fixed Carthage compatibility by disabling the SwiftLint build phase in release builds. [#1619](https://github.com/Moya/Moya/pull/1619) by [@Dschee](https://github.com/Dschee).

# [11.0.1] - 2018-02-26
### Fixed
- Fixed Alamofire validation not being performed on `.uploadMultipart` requests.
  [#1591](https://github.com/Moya/Moya/pull/1591) by [@SD10](https://github.com/SD10).
- Fixed Alamofire validation not being performed on stubbed requests.
  [#1593](https://github.com/Moya/Moya/pull/1593) by [@SD10](https://github.com/sd10).

# [11.0.0] - 2018-02-07
- No changes

# [11.0.0-beta.2] - 2018-01-27
## Changed
- **Breaking Change** Removed generic from `Endpoint`. See #1524 for discussion. [#1529](https://github.com/Moya/Moya/pull/1529) by @[zhongwuzw](https://github.com/zhongwuzw).

# [11.0.0-beta.1] - 2018-01-10
### Added
- **Breaking Change** Added a `.requestCustomJSONEncodable` case to `Task`. [#1443](https://github.com/Moya/Moya/pull/1443) by [@evgeny-sureev](https://github.com/evgeny-sureev).
- **Breaking Change** Added `failsOnEmptyData` boolean support for the `Decodable` map functions. [#1508](https://github.com/Moya/Moya/pull/1508) by [@jeroenbb94](https://github.com/Jeroenbb94).

### Changed
- **Breaking Change** Updated minimum version of `ReactiveSwift` to 3.0.
  [#1470](https://github.com/Moya/Moya/pull/1470) by [@larryonoff](https://github.com/larryonoff).
- **Breaking Change** Changed the `validate` property of `TargetType` to use new `ValidationType` enum representing valid status codes. [#1505](https://github.com/Moya/Moya/pull/1505) by [@SD10](https://github.com/sd10), [@amaurydavid](https://github.com/amaurydavid). 

# [10.0.2] - 2018-01-26
### Fixed
- Fixed a bug where modifying `.uploadMultipart`, `.uploadCompositeMultipart`, `.uploadFile`, `.downloadDestination`, and `.downloadParameters` tasks through an `endpointClosure` has no effect on the final request.
  [#1550](https://github.com/Moya/Moya/pull/1550) by [@SD10](https://github.com/sd10), [@sunshinejr](https://github.com/sunshinejr).
- Fixed a bug where `URLEncoding.httpBody` wasn't allowed as `bodyEncoding` in `Task.requestCompositeParameters()`. [#1557](https://github.com/Moya/Moya/pull/1557) by [@sunshinejr](https://github.com/sunshinejr).

# [10.0.1] - 2017-11-23
### Fixed
- Fixed a bug that `Decodable` mapping to object other than Array and Dictionary in a key path cause crash. [#1405](https://github.com/Moya/Moya/pull/1405) by [@ufosky](https://github.com/ufosky).
- Fixed a bug with missing Content-Type header when using `.requestJSONEncodable` [#1410](https://github.com/Moya/Moya/pull/1410) by [@Vict0rS](https://github.com/Vict0rS).
- Fixed linker settings, enabling RxMoya and ReactiveMoya to be used in app extensions [#1417](https://github.com/Moya/Moya/pull/1417) by [@spookyvision](https://github.com/spookyvision/).
- Fixed carthage OS X not targeting 10.10 [#1444](https://github.com/Moya/Moya/pull/1444) by [@lucas34](https://github.com/lucas34).

# [10.0.0] - 2017-10-21
### Fixed
- Fixed a bug that `Decodable` mapping won't decode nested JSON array in a key path [#1382](https://github.com/Moya/Moya/pull/1382) by [@devxoul](https://github.com/devxoul).

# [10.0.0-beta.1] - 2017-10-08
### Added
- **Breaking Change** Added a `.parameterEncoding` case to `MoyaError`. [#1248](https://github.com/Moya/Moya/pull/1248) by [@SD10](https://github.com/SD10).
- **Breaking Change** Added an `.objectMapping` case to `MoyaError`. [#1335](https://github.com/Moya/Moya/pull/1335) by [@devxoul](https://github.com/devxoul).
- **Breaking Change** Added an`.encodableMapping` case to `MoyaError`. [#1349](https://github.com/Moya/Moya/pull/1349) by [@LeLuckyVint](https://github.com/LeLuckyVint), [@afonsograca](https://github.com/afonsograca) and [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** Added a `.requestJSONEncodable` case to `Task`. [#1349](https://github.com/Moya/Moya/pull/1349) by [@LeLuckyVint](https://github.com/LeLuckyVint), [@afonsograca](https://github.com/afonsograca) and [@sunshinejr](https://github.com/sunshinejr).
- Added a `Decodable` object mapping methods to `Moya.Response`. [#1335](https://github.com/Moya/Moya/pull/1335) by [@devxoul](https://github.com/devxoul).

### Changed
- **Breaking Change** Changed `Endpoint.init` so it doesn't have any default arguments (removing default argument `.get` for `method` parameter and `nil` for  `httpHeaderFields` parameter). [#1289](https://github.com/Moya/Moya/pull/1289) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** Changed `NetworkActivityPlugin` so its `networkActivityClosure` has now `target: TargetType` argument in addition to `change: NetworkActivityChangeType`. [#1290](https://github.com/Moya/Moya/pull/1290) by [@sunshinejr](https://github.com/sunshinejr).
- **Breaking Change** Changed `Endpoint`'s `urlRequest` property to `urlRequest()` a throwing method. [#1248](https://github.com/Moya/Moya/pull/1248) by [@SD10](https://github.com/SD10).

### Removed
- **Breaking Change** Removed `RxMoyaProvider` and `ReactiveSwiftMoyaProvider`. [#1320](https://github.com/Moya/Moya/pull/1320) by [@SD10](https://github.com/SD10)

### Fixed
- Fixed a `MoyaProvider+Rx` self-retaining bug in `requestWithProgress`. [#1311](https://github.com/Moya/Moya/pull/1311) by [@AndrewSB](https://github.com/AndrewSB).

# [9.0.0] - 2017-09-04
- Removed default value for task from `Endpoint` initializer

# [9.0.0-beta.1] - 2017-08-26
### Changed
- **Breaking Change** Replaced `parameters` & `parameterEncoding` in `TargetType` with extended `Task` cases.
- **Breaking Change** Flattened `UploadType` and `DownloadType` into `Task` cases.
- **Breaking Change** Replaced `shouldAuthorize: Bool` in `AccessTokenAuthorizable` with `authorizationType: AuthorizationType`.
- **Breaking Change** Replaced `token` in `AccessTokenPlugin` with `tokenClosure`.
- **Breaking Change** `TargetTypes` no longer receive the `Authorization: Bearer <token>` header by default when using `AccessTokenPlugin`.

### Added
- Added Swift 4.0 support for Moya core (without RxSwift/ReactiveSwift extensions for now).
- Added all the `filter`/`map` operators that were available for `Observable<Response>` to `Single<Response>` as well.
- Added `AuthorizationType` to `AccessTokenAuthorizable` representing request headers of `.none`, `.basic`, and `.bearer`.
- Added tests for `Single<Response>` operators.
- Added `Progress` object into the response when calling progress callback on completion.
- Added tests for creating `URLRequest` from `Task`.

### Fixed
- Fixed a bug where you weren't notified on progress callback for data request.

# [9.0.0-alpha.1] - 2017-0729
### Changed
- **Breaking Change** Added support to get the response (if any) from `MoyaError`.
- **Breaking Change** Added `headers` to `TargetType`.
- **Breaking Change** Updated `RxMoyaProvider.request` to return a [`Single<Request>`](https://github.com/ReactiveX/RxSwift/pull/1123).
- **Breaking Change** Updated `Moya.Response`'s `response`to use an `HTTPURLResponse` instead of a `URLResponse`.
- **Breaking Change** Renamed all occurrences of `queue` to `callbackQueue`.
- **Breaking Change** Deprecated `ReactiveSwiftMoyaProvider` and `RxSwiftMoyaProvider`. Use `MoyaProvider` with reactive properties now: `provider.reactive._`, `provider.rx._`. In case you were subclassing reactive providers, please take a look at [this PR from Eidolon](https://github.com/artsy/eidolon/pull/669). It covers migration from subclassing given providers, to usage by composition.
- **Breaking Change** Removed parameter name in `requestWithProgress` for `ReactiveSwiftMoyaProvider`.
- **Breaking Change** Removed deprecated in Moya 8.0.0: `Moya.Error`, `endpointByAddingParameters(parameters:)`, `endpointByAddingHttpHeaderFields(httpHeaderFields:)`, `endpointByAddingParameterEncoding(newParameterEncoding:)`, `endpointByAdding(parameters:httpHeaderFields:parameterEncoding)`, `StructTarget`, `filterStatusCodes(range:)`, `filterStatusCode(code:)`, `willSendRequest(request:target:)`, `didReceiveResponse(result:target:)`, `ReactiveCocoaMoyaProvider`, `ReactiveSwiftMoyaProvider.request(token:)`.

### Added
- Added optional callback queue parameter to reactive providers.
- Added public `URL(target:)` initializator that creates url from `TargetType`.
- Added an optional `requestDataFormatter`in `NetworkLoggerPlugin` to allow the client to interact with the request data before logging it.

### Fixed
- Fixed a bug where you would have two response events in `requestWithProgress` method on `ReactiveSwift` module.
- Enabled the "Allow app extension API only" flag.

- Updated minimum version of `RxSwift` to `3.3`.
- Updated minimum version of `ReactiveSwift` to 2.0.

# [8.0.5] - 2017-05-26
### Fixed
- Fixed a bug where you would have two response events in `requestWithProgress` method on RxMoya module.

# [8.0.4] - 2017-05-09
### Changed
- Bumped minimum version of ReactiveSwift to 1.1.
- Changed use of deprecated `DateSchedulerProtocol` to `DateScheduler`.
- Move project to using a single target for all platforms.
- Changed default endpoint creation to only append `path` to `baseURL` when `path` is not empty.

# [8.0.3] - 2017-03-13
### Fixed
- Fixed `reversedPrint` arguments for output.
- Fixed memory leak when request with stub.

### Changed
- Changed `Moya.Error` to `MoyaError` in `MoyaAvailablity` for Swift 3.1 compatibility.

# [8.0.2] - 2017-02-01
### Changed
- Changed dependency pinning to rely only on major versions.

# [8.0.1] - 2017-01-21
### Fixed
- Fixed an issue where `RxMoyaProvider` never sends `next` or errors if it's disposed before a subscription is made.

# [8.0.0] - 2017-01-04
### Changed
- **Breaking Change** Renamed `Moya.Error` to `MoyaError`.
- **Breaking Change** Renamed `verbose` in the NetworkLoggerPlugin to `isVerbose`.
- **Breaking Change** `TargetType` now specifies its `ParameterEncoding`.
- **Breaking Change** Removed unused `Moya.Error.data`.
- **Breaking Change** Renamed `adding(newHttpHeaderFields:)` to `adding(newHTTPHeaderFields:)`.

### Added
- Supported the Swift package manager
- Added `AccessTokenPlugin` for easier authorization.
- Added `AccessTokenAuthorizable` protocol for optionally controlling the authorization behavior of `TargetType`s when using `AccessTokenPlugin`.
- Added availability tags for renamed functions included in the Swift 3 migration.
- `Moya.Error` now conforms to `LocalizedError` protocol.
- Added documentation for `TargetType` and associated data structures.
- Re-add `MultiTarget` to project.

### Changed
- Adopted an SPM-compatible project structure.
- Moved tests to Moya.xcodeproj.

# [8.0.0-beta.6] - 2016-12-14
### Changed
- **Breaking Change** Renamed `ReactiveCocoaMoyaProvider` to `ReactiveSwiftMoyaProvider`.
- **Breaking Change** Renamed `PluginType` functions to comply with Swift 3 design guideline:
  - `willSendRequest` renamed to `willSend`.
  - `didReceiveResponse` renamed to `didReceive`.
- **Breaking Change** Renamed `filterStatusCodes(:)` to `filter(statusCodes:)` (and `filterStatusCode(:)` to `filter(statusCode:)`).
- **Breaking Change** Renamed `request(token:)` to simply `request(:_)` (ReactiveSwift).
- **Breaking Change** Renamed `notifyPluginsOfImpendingStub(request:)` to `notifyPluginsOfImpendingStub(for:)`.
- Renamed the `ReactiveCocoa` subspec to `ReactiveSwift`.
- `PluginType` can now modify requests and responses through `prepare` and `process`

# [8.0.0-beta.5] - 2016-11-29
### Changed
- **Breaking Change** Renamed `cancelled` in the `Cancellable` protocol to `isCancelled`.
- **Breaking Change** Renamed `URL` in `Endpoint` to `url`.
- **Breaking Change** Renamed `StructTarget` to `MultiTarget`.
- Demo project has been updated with new DemoMultiTarget target, new project
  structure and more.

### Added
- Readded support for iOS 8 and macOS 10.10.
- Added _validate_ option in `TargetType`, to allow enabling Alamofire automatic validation on requests.
- Added `mapString(atKeyPath:)` to `Response`, `SignalProducerProtocol`, and `ObservableType`

# [8.0.0-beta.4] - 2016-11-08
### Changed
- **Breaking Change** Made some `class func`s [mimicking enum cases](https://github.com/Moya/Moya/blob/master/Source/Moya.swift#L117-L133) lowercased.
- Updates for RxSwift 3.0 final release.

### Added
- Added default empty implementation for `willSendRequest` and `didReceiveResponse` in `PluginType`.
- Use `String(data:encoding:)` instead of `NSString(data:encoding:)` while converting `Data` to `String`.

# [8.0.0-beta.3] - 2016-10-17
### Changed
- **Breaking Change** Throw dedicated `Error.jsonMapping` when `mapJSON` fails to parse JSON.
- **Breaking Change** Renamed `endpointByAddingHTTPHeaders` to `adding(newHttpHeaderFields:)`.
- **Breaking Change** Renamed `endpointByAddingParameters` to `adding(newParameters:)`.
- **Breaking Change** Renamed `endpointByAddingParameterEncoding` to `adding(newParameterEncoding:)`.
- **Breaking Change** Renamed `endpointByAdding(parameters:httpHeaderFields:parameterEncoding)` to `adding(parameters:httpHeaderFields:parameterEncoding)`.
- **Breaking Change** Changed HTTP verbs enum to lowercase.
- `urlRequest` property of `Endpoint` is now truly optional. The request will fail if the `urlRequest` turns out to be nil and a `requestMapping` error will be returned together with the problematic url.
- **Breaking Change** Made RxMoya & ReactiveMoya frameworks dependant on Moya framework, making them slimmer and not re-including Moya source in the Reactive extensions. ([PR](https://github.com/Moya/Moya/pull/563))
- Removed the unused `StreamRequest` typealias that was causing watchOS failures.

### Fixed
- Fixes download requests never calling the completion block.

### Added
- Added a new internal Requestable protocol.
- Added a new case to `SampleResponseClosure` which allows mocking of the whole `URLResponse`.
- Added a test for new `SampleResponseClosure` case.

# [8.0.0-beta.2] - 2016-09-22
### Changed
- **Breaking Change** Transition from ReactiveCocoa to ReactiveSwift. ([PR](https://github.com/Moya/Moya/pull/661))

# [8.0.0-beta.1] - 201609-19
### Changed
- **Breaking Change** Support for `Swift 3` in favor of `Swift 2.x`.
- **Breaking Change** `fileName` and `mimeType` are now optional properties on a MultipartFormData object.
- Correct Alamofire `appendBodyPart` method id called in MultipartFormData.
- **Breaking Change** Removes `multipartBody` from TargetType protocol and adds a `task` instead.
- **Breaking Change** Successful Response instances that have no data with them are now being converted to `.Success` `Result`s.

### Added
- Adds Download and Upload Task type support to Moya.
- Added `supportsMultipart` to the `Method` type, which helps determine whether to use `multipart/form-data` encoding.
- Added `PATCH` and `CONNECT` to the `Method` cases which support multipart encoding.
- Added `request` for `Response`.

### Fixed
- Corrects SwiftLint warnings.
- Separates `Moya.swift` into multiple files.
- Updated `mapJSON` API to include an optional named parameter `failsOnEmptyData:` that when overridden returns an empty `NSNull()` result instead of throwing an error when the response data is empty.


# [7.0.4] - 2016-12-07
### Fixed
- Fixes bug for MultipartFormData constructor in Swift 2.3 where fields and files were given a mimetype, forcing them both to be added to the 'files' section.
- Multipart form constructor contains optional Strings

# [7.0.3] - 2016-09-15
### Added
- Carthage support for Swift 2.3.

# [7.0.2] - 2016-09-14
### Added
- Swift 2.3 support.

# [7.0.1] - 2016-09-13

- Identical to 7.0.0, see [#594](https://github.com/Moya/Moya/pull/594) for an explanation.

# [7.0.0] - 2016-07-14
### Changed
- **Breaking Change** Drops support for `RACSignal`.
- **Breaking Change** Changes `Moya.Error.Underlying` to have `NSError` instead of `ErrorType`.
- **Breaking Change** Implements inflights tracking by adding `trackInflights = true` to your provider.
- **Breaking Change** Changes `MoyaProvider.RequestClosure` to have `Result<NSURLRequest, Moya.Error> -> Void` instead of `NSURLRequest -> Void` as a `done` closure parameter.
- **Breaking Change** New community guidelines.
- New multipart file upload.
- New cURL-based logging plugin.
- Moves from OSSpinLock to `dispatch_semaphor` to avoid deadlocks.

### Added
- Integrates Danger into the repo.

### Fixed
- Fixes a xcodeproj referencing bug introduced by the new cURL-based logging plugin.
- Calls completion even when cancellable token is canceled

# [6.5.0] - 2016-05-26
### Added
- Added `queue` parameter to `request` and `sendRequest`. This open up option to use other queue instead of main queue for response callback.

# [6.4.0] - 2016-04-02
### Changed
- Makes `convertResponseToResult` public to make use of this method when dealing with Alamofire directly
- Updates to ReactiveCocoa 4.1
- Updates to Result 2.0

# [6.3.1] - 2016-03-25
### Changed
- Updates for Swift 2.2 / Xcode 7.3 compatibility.

# [6.3.0] - 2016-03-16
### Fixed
- Fixed endpoint setup when adding `parameters` or `headers` when `parameters` or `headers` or nil.

### Added
- Adds StructTarget for using Moya with structs.

# [6.2.0] - 2016-02-26
### Added
- Adds `response` computed property to `Error` type, which yields a Response object if available.
- Added URLEncodedInURL to ParameterEncoding.
- Adds convenience `endpointByAdding` method.

### Changed
- Remove our own implementation of `ParameterEncoding` and make it a `public typealias` of `Alamofire.ParameterEncoding`.

# [6.1.3] - 2016-02-01
### Changed
- Updated to ReactiveCocoa 4.0 final.

### Added
- Added formatter parameter to plugin for pretty-printing response data. See #392.

# [6.1.2] - 2016-01-28
### Added
- Compatibility with RxSwift 2.x.

# [6.1.1] - 2016-01-17
### Added
- Compatibility with RxSwift 2.1.x.

# [6.1.0] - 2016-01-26
### Changed 
- The built-in `DefaultAlamofireManager` as parameter's default value instead of the singleton `Alamofire.Manager.sharedinstance` is now used when instantiating `ReactiveCocoaMoyaProvider` and `RxMoyaProvider` as well.

# [6.0.1] - 2016-01-26
### Changed
- Updates to ReactiveCocoa 4 RC 2.

# [6.0.0] - 2016-01-05
### Changed
- **Breaking Change** pass a built-in `DefaultAlamofireManager` as parameter's default value instead of passing the singleton `Alamofire.Manager.sharedinstance` when initialize a `provider`
- Fixes issue that stubbed responses still call the network.

# [5.3.0] - 2016-01-02
### Changed
- Updates to RXSwift 2.0.0
- Moves to use Antitypical/Result

# [5.2.1] - 2015-12-21
### Changed
- Update to ReactiveCocoa v4.0.0-RC.1
- Moves to antitypical Result type

### Fixed
- Fixes cases where underlying network errors were not properly propagated.

# [5.2.0] - 2015-12-xx
### Changed
- Updated to RxSwift 2.0.0-beta.4

# [5.1.0] - 2014-12-08
### Changed
- Update to ReactiveCocoa v4.0.0-alpha.4

# [5.0.0] - 2015-11-30
### Changed
- **Breaking Change** rename `MoyaTarget` protocol to `TargetType`
- **Breaking Change** rename `MoyaRequest` protocol to `RequestType`
- **Breaking Change** rename `Plugin` protocol to `PluginType`
- Removes conversion from `Moya.Method` to `Alamofire.Method` since it was unused
- Changes `NetworkLoggingPlugin`'s initializer to also take a function that has the same signature as `print` to simplify testing
- **Breaking Change** renames `ParameterEncoding`'s `parameterEncoding` method to `toAlamofire` and makes it internal only
- **Breaking Change** `Plugin<Target>` is now a protocol and as such no longer sends a typed `MoyaProvider`. - @swizzlr
- **Breaking Change** The types that were subtypes of `Moya` are now defined at the top level; you should find no compatibility issues since they are still invoked by `Moya.X` – @swizzlr
- **Breaking Change** `Completion` closure now returns a `Result` instead of multiple optional parameters.
- **Breaking Change** `MoyaResponse` is now `Response`, and also `final`. It will be changed to a `struct` in a future release. - @swizzlr
- **Breaking Change** `ReactiveCocoaMoyaProvider` can now be supplied with an optional `stubScheduler` – @swizzlr (sponsored by [Network Locum](https://networklocum.com))
- **Breaking Change** Introduce `Error` type for use with reactive extensions - [@tomburns](http://github.com/tomburns)
- **Breaking Change** Deprecate ReactiveCocoa 2 support

# [4.5.0] - 2015-11-11
### Added
- Adds mapping methods to `MoyaResponse`

# [4.4.0] - 2015-11-06
### Added
- Adds tvOS and watchOS support

### Fixed
- Fixes carthage OS X target not having source files

### Changed
- Makes base OS X target 10.9 instead of 10.10

# [4.3.1] - 2015-11-02
### Changed
- Updates to latest ReactiveCocoa alpha. Again.

# [4.3.0] - 2015-11-02
### Changed
- Updates to latest ReactiveCocoa alpha.

# [4.2.0] - 2015-11-02
### Changed
- Removed extraneous `SignalProducer` from ReactiveCocoa extension – @JRHeaton
- Removed extraneous `deferred()` from RxSwift extension
- Moved to new RxSwift syntax – @wouterw
- Updated RxSwift to latest beta – @wouterw

# [4.1.0] - 2015-10-27
### Added
- OS X support.

# [4.0.3] - 2015-10-23
### Fixed
- Fixes Carthage integration problem.

# [4.0.2] - 2015-10-23
### Added
- CancellableTokens can now debug print the requests cURL.

# [4.0.1] - 2015-10-13
### Changed
- Plugins now subclasses NSObject for custom subclasses.
- Plugins' methods are now public, allowing custom subclasses to override.

# [4.0.0] - 2015-10-12
### Changed
- Updates Alamofire dependency to `~> 3.0`

# [3.0.1] - 2015-10-08
### Changed
- Changes `mapImage()` RxSwift function to use `UIImage!` instead of `UIImage`.

# [3.0.0] - 2015-10-05
### Changed
- Makes `parameters` on `MoyaTarget` an optional `[String: AnyObject]` dictionary.
- Makes `parameters` and `httpHeaderFields` on `Endpoint` to be optionals.
- Renamed stubbing identifiers: **Breaking Change**
  - `Moya.StubbedBehavior` renamed to `Moya.StubBehavior`
  - `Moya.MoyaStubbedBehavior` renamed to `Moya.StubClosure`
  - `Moya.NoStubbingBehavior` -> `Moya.NeverStub`
  - `Moya.ImmediateStubbingBehaviour` -> `Moya.ImmediatelyStub`
  - `Moya.DelayedStubbingBehaviour` -> `Moya.DelayedStub`
- Default class functions have been moved to extensions to prevent inadvertent subclassing.
- Renamed other identifiers: **Breaking Change**
  - `MoyaProvider.MoyaEndpointsClosure` to `MoyaProvider.EndpointClosure`
  - `MoyaProvider.MoyaEndpointResolution` to `MoyaProvider.RequestClosure`
  - `MoyaProvider.endpointResolver` to `MoyaProvider.requestClosure`
  - `MoyaProvider.stubBehavior` to `MoyaProvider.stubClosure`
  - `MoyaCredentialClosure` to `CredentialClosure`
  - `MoyaProvider` initializer parameter names
  - `MoyaCompletion` to `Moya.Completion`
  - `DefaultEndpointResolution` to `DefaultRequestMapping`
- Renamed `T` generic types of `MoyaProvider` and `Endpoint` classes to `Target`.
- Removed errantly named `DefaultEndpointResolution`
- Changes the closure to map `Endpoint`s to `NSURLRequest`s asynchonous.
- Removes inflight request tracking for ReactiveCocoa and RxSwift providers. **Breaking Change**
- Renamed `EndpointSampleResponse` cases: **Breaking Change**
  - `Success` to `NetworkResponse`, now contains `NSData` instead of `() -> NSData`.
  - `Error` to `NetworkError`
  - Additionally, `NetworkError` no longer has a status code or data associated with it. This represents an error from the underlying iOS network stack, like an inability to connect. See [#200](https://github.com/Moya/Moya/issues/200) for more details.
  - Also additionally, removed `Closure` case (see below).
- Changed `Endpoint` to use a `sampleResponseClosure` instead of a `sampleResponse`, making all sample responses lazily executed. **Breaking Change**
- New plugin architecture **Breaking Change**
  - This replaces `networkActivityClosure` with a plugin.
- ReactiveCocoa provider no longer replaces errors that contain status codes (an unlikely situation) with its own errors. It passes all errors directly through.
- Renames `token` to `target` (it was usually `target` anyway, just made it consistent).

### Added
- Adds support for ReactiveCocoa 4 by moving `ReactiveCocoaMoyaProvider` to use `SignalProducer` instead of `RACSignal`

# [2.4.1] - 2015-09-22
### Fixed
- Corrects problem with ignoring the specified Alamofire manager

# [2.4.0] - 2015-09-22
### Added
- Adds HTTP basic auth support.

# [2.3.0] - 2015-09-22
### Added
- Adds data processing functions for use with `RxMoyaProvider`

# [2.2.2] - 2015-09-16
### Added
- Adds convenience `endpointByAddingParameterEncoding` method.

# [2.2.1] - 2015-09-14
### Added
- Adds Moya files as members of RxMoya and ReactiveMoya frameworks.

# [2.2.0] - 2015-09-14
### Added
- Add backward-compatible call from `DefaultEnpointResolution` to `DefaultEndpointResolution` on `MoyaProvider` class. `DefaultEndpointResolution` is now used internally as the default resolver. `DefaultEnpointResolution` can be removed in a future major release.
- Carthage support.

# [2.1.0] - 2015-08-11
### Added
- Add option to pass an `Alamofire.Manager` to `MoyaProvider` initializer

# [2.0.2] - 2015-08-11
### Changed
- Updates Demo directory's RxSwift version.

# [2.0.1] - 2015-08-06
### Changed
- Updates Demo directory's Moya version for `pod try` compatbility.

# [2.0.0] - 2015-08-04
### Changed
- **Breaking change** Combines `MoyaPath` and `MoyaTarget` protocols.
- **Breaking change** Renames `Moya/Reactive` subspec to `Moya/ReactiveCocoa`.
- **Breaking change** Removes `stubResponses` from initializer; replaced with new stubbing behavior `.NoStubbing`. Added class methods to `MoyaProvider` to provide defaults, while allowing users to still change stubbing behavior on a per-request basis.
- **Breaking change** Redefines types of `DefaultEndpointMapping` and `DefaultEnpointResolution` class functions on `MoyaProvider`. You no longer invoke these functions to return a closure, rather, you reference the functions themselves _as_ closures.
- **Breaking change** Renames `endpointsClosure` parameter and property of `MoyaProvider` to `endpointClosure`.
- **Breaking change** Renames `ReactiveMoyaProvider` to `ReactiveCocoaMoyaProvider` for consistency.
- Relaxes version dependency on RxSwift - [@alcarvalho](http://github.com/alcarvalho)

### Added
- Adds official Carthage support – [@neonichu](http://github.com/neonichu)

### Fixed
- Fixes problem that the `ReactiveMoyaProvider` initializer would not respect the stubbing behavior it was passed.
- Fixes possible concurrency bugs with reactive providers - [@alcarvalho](http://github.com/alcarvalho)

# [1.1.1] - 2015-06-12
### Fixed
- Fixes problem where `RxMoyaProvider` would not respect customized stubbing behavior (delays).

# [1.1.0] - 2015-06-08
### Added
- Adds support for RxSwift – [@alcarvalho](http://github.com/alcarvalho)

# [1.0.0] - 2015-05-27
### Changed
- **Breaking change** Changes `EndpointSampleResponse` to require closures that return `NSData`, not `NSData` instances themselves. This prevents sample data from being loaded during the normal, non-unit test app lifecycle.
- **Breaking change** Adds `method` to `MoyaTarget` protocol and removes `method` parameter from `request()` functions. Targets now specify GET, POST, etc on a per-target level, instead of per-request.
- **Breaking change** Adds `parameters` to `MoyaTarget` protocol and removes ability to pass parameters into `request()` functions. Targets now specify the parameters directly on a per-target level, instead of per-request.
- Adds a sane default implementation of the `MoyaProvider` initializer's `endpointsClosure` parameter.

# [0.8.0] - 2015-05-25
### Changed
- Updates to Swift 1.2.

# [0.7.1] - 2015-05-27
### Added
- Adds cancellable requests -[@MichaelMcGuire](http://github.com/MichaelMcGuire)

# [0.7.0] - 2015-04-27
### Added
- Adds network activity closure to provider.

# [0.6.1] - 2017-01-13
### Changed
- Updates podspec to refer to `3.0.0-aplha.1` of ReactiveCocoa. -[@ashfurrow](http://github.com/ashfurrow)

# [0.6] - 2015-01-11
### Added
- First release on CocoaPods trunk.
- Add data support for [stubbed error responses](https://github.com/ashfurrow/Moya/pull/92). – [@steam](http://github.com.steam)

### Fixed
- Fixes [#66](https://github.com/AshFurrow/Moya/issues/66), a problem with outdated Alamofire dependency and it's serializer type signature. -[@garnett](http://github.com/garnett)

### Changed
- Delete note about ReactiveCocoa installation -[@garnett](http://github.com/garnett)

# [0.5] - 2014-10-09
### Fixed
- Fixes [#52](https://github.com/AshFurrow/Moya/issues/52) to change submodules to use http instead of ssh. -[@ashfurrow)](http://github.com/AshFurrow)
- Fixes [#63](https://github.com/AshFurrow/Moya/issues/63), a problem where stale inflight requests were kept around if they error'd down the pipline (discussed [here](https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1525#issuecomment-58559734)) -[@ashfurrow](http://github.com/AshFurrow)

### Added
- Adds the original NSURLResponse to a MoyaResponse -[@orta)](http://github.com/orta)

### Changed
- Migrate to support Xcode beta 6.1 -[@orta)](http://github.com/orta)


# [0.4] -2014-09-22
### Added
- Implements [#46](https://github.com/AshFurrow/Moya/issues/46), the code property of the NSError sent through by ReactiveMoyaProvider will now match the failing http status code. -[@powerje](http://github.com/powerje)

# [0.3] - 2014-09-12
### Fixed
- Fixes [#48](https://github.com/AshFurrow/Moya/issues/48) that modifies Moya to execute completion blocks of stubbed responses *immediately*, instead of using `dispatch_async` to defer it to the next invocation of the run loop. **This is a breaking change**. Because of this change, the ReactiveCocoa extensions had to be modified slightly to deduplicate inflight stubbed requests. Reactive providers now vend `RACSignal` instances that start the network request *when subscribed to*. -[@ashfurrow](http://github.com/AshFurrow)

# [0.2] - 2014-09-15
### Fixed
- Fixes [#44](https://github.com/AshFurrow/Moya/issues/44) where status codes weren't being passed through to completion blocks. This also modified the behavior of the ReactiveCocoa extensions significantly but sending MoyaResponse objects instead of just NSData ones. —[@ashfurrow](http://github.com/AshFurrow)

# [0.1] - 2014-09-07

- Initial release.
