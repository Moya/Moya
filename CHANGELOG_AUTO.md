# Change Log

## [Unreleased](https://github.com/ashfurrow/Moya/tree/HEAD)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.8.0...HEAD)

**Implemented enhancements:**

- Swift 1.2 branch needs @autoclosure back [\#108](https://github.com/ashfurrow/Moya/issues/108)

- Jazzy documentation [\#81](https://github.com/ashfurrow/Moya/issues/81)

- Bit weird that a non-stubbed provider still pulls in data for stubbed response [\#65](https://github.com/ashfurrow/Moya/issues/65)

- Clarify benefits of using Moya over vanilla Alamofire [\#51](https://github.com/ashfurrow/Moya/issues/51)

**Fixed bugs:**

- Custom URL encoding requires importing Alamofire [\#91](https://github.com/ashfurrow/Moya/issues/91)

- MoyaErrorDomain must be public [\#70](https://github.com/ashfurrow/Moya/issues/70)

**Closed issues:**

- Update to Support Latest Swift & Dependencies [\#113](https://github.com/ashfurrow/Moya/issues/113)

- Use URL caching to avoid hitting the network for integration tests [\#110](https://github.com/ashfurrow/Moya/issues/110)

- More of a "how do I", maybe a feature request. [\#102](https://github.com/ashfurrow/Moya/issues/102)

- Distribute to AppStore [\#88](https://github.com/ashfurrow/Moya/issues/88)

- Impossible to use Moya as submodule/workspace project [\#85](https://github.com/ashfurrow/Moya/issues/85)

## [0.8.0](https://github.com/ashfurrow/Moya/tree/0.8.0) (2015-05-25)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.7.1...0.8.0)

**Merged pull requests:**

- Swift 1.2 [\#122](https://github.com/ashfurrow/Moya/pull/122) ([ashfurrow](https://github.com/ashfurrow))

## [0.7.1](https://github.com/ashfurrow/Moya/tree/0.7.1) (2015-05-25)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.7.0...0.7.1)

**Closed issues:**

- Cancelable Network requests [\#119](https://github.com/ashfurrow/Moya/issues/119)

**Merged pull requests:**

- Adding cancelable behavior to MoyaProvider requests [\#120](https://github.com/ashfurrow/Moya/pull/120) ([MichaelMcGuire](https://github.com/MichaelMcGuire))

- Swift 1.2 upgrade [\#116](https://github.com/ashfurrow/Moya/pull/116) ([skywinder](https://github.com/skywinder))

- Reference Demo, not Sample, directory [\#115](https://github.com/ashfurrow/Moya/pull/115) ([stephencelis](https://github.com/stephencelis))

## [0.7.0](https://github.com/ashfurrow/Moya/tree/0.7.0) (2015-04-22)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.6.1...0.7.0)

**Fixed bugs:**

- MoyaResponse is crashing when used with ReactiveCocoa [\#78](https://github.com/ashfurrow/Moya/issues/78)

**Closed issues:**

- Moya doesn't compile on XC 6.3 beta 4, Swift 1.2 [\#106](https://github.com/ashfurrow/Moya/issues/106)

- Difficulty installing with ReactiveCocoa and LlamaKit using the method described in your docs. [\#104](https://github.com/ashfurrow/Moya/issues/104)

- filterSuccessfulStatusCodes [\#103](https://github.com/ashfurrow/Moya/issues/103)

- CocoaPods+Moya [\#101](https://github.com/ashfurrow/Moya/issues/101)

- Moya+ReactiveCocoa should support HTTP headers [\#99](https://github.com/ashfurrow/Moya/issues/99)

- Delay in stubs [\#95](https://github.com/ashfurrow/Moya/issues/95)

**Merged pull requests:**

- @orta =\> Adds Network Activity Thingies [\#112](https://github.com/ashfurrow/Moya/pull/112) ([ashfurrow](https://github.com/ashfurrow))

- Update Moya.podspec for new major Alamofire version [\#109](https://github.com/ashfurrow/Moya/pull/109) ([vandyshev](https://github.com/vandyshev))

- \[WIP\] swift 1.2 support [\#107](https://github.com/ashfurrow/Moya/pull/107) ([aschuch](https://github.com/aschuch))

- added filterSuccessfulStatusAndRedirectCodes [\#105](https://github.com/ashfurrow/Moya/pull/105) ([aschuch](https://github.com/aschuch))

- \[WIP\] Adds 'Lazy' type, so sampleData can be requested later [\#100](https://github.com/ashfurrow/Moya/pull/100) ([colinta](https://github.com/colinta))

- Fixed code samples to reflect the real apis [\#98](https://github.com/ashfurrow/Moya/pull/98) ([raphaelmor](https://github.com/raphaelmor))

- fixes \#78 [\#97](https://github.com/ashfurrow/Moya/pull/97) ([aschuch](https://github.com/aschuch))

- @orta =\> Adds optional delay to stubs [\#96](https://github.com/ashfurrow/Moya/pull/96) ([ashfurrow](https://github.com/ashfurrow))

- Delete .gitmodules [\#94](https://github.com/ashfurrow/Moya/pull/94) ([jspahrsummers](https://github.com/jspahrsummers))

## [0.6.1](https://github.com/ashfurrow/Moya/tree/0.6.1) (2015-01-13)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.6...0.6.1)

**Implemented enhancements:**

- Update README for new CocoaPods instructions [\#93](https://github.com/ashfurrow/Moya/issues/93)

## [0.6](https://github.com/ashfurrow/Moya/tree/0.6) (2015-01-11)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.5...0.6)

**Implemented enhancements:**

- Documentation [\#68](https://github.com/ashfurrow/Moya/issues/68)

- Use NSError to relay status codes [\#46](https://github.com/ashfurrow/Moya/issues/46)

**Closed issues:**

- Custom ParameterEncodings [\#90](https://github.com/ashfurrow/Moya/issues/90)

- the "Project readme" linked in the readme gives 404  [\#89](https://github.com/ashfurrow/Moya/issues/89)

- Unable to use Moya with CocoaPods [\#84](https://github.com/ashfurrow/Moya/issues/84)

- Travis CI [\#76](https://github.com/ashfurrow/Moya/issues/76)

-  'URLRequestConvertible' is not a subtype of 'NSURLRequest' [\#66](https://github.com/ashfurrow/Moya/issues/66)

- Not sure 401s are being handled correctly [\#57](https://github.com/ashfurrow/Moya/issues/57)

**Merged pull requests:**

- Add data support for stubbed error responses. [\#92](https://github.com/ashfurrow/Moya/pull/92) ([steam](https://github.com/steam))

- Fixes \#84. [\#86](https://github.com/ashfurrow/Moya/pull/86) ([ashfurrow](https://github.com/ashfurrow))

- Fixed very small typo in README [\#83](https://github.com/ashfurrow/Moya/pull/83) ([ryancrosby](https://github.com/ryancrosby))

- Fix CocoaPods install instructions for remote pods [\#80](https://github.com/ashfurrow/Moya/pull/80) ([interstateone](https://github.com/interstateone))

- @orta =\> Updates with CocoaPods instructions. [\#79](https://github.com/ashfurrow/Moya/pull/79) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Continuous Integration [\#77](https://github.com/ashfurrow/Moya/pull/77) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Documentation [\#75](https://github.com/ashfurrow/Moya/pull/75) ([ashfurrow](https://github.com/ashfurrow))

- Fixed a minor bug that prevented compilation of the sample. [\#72](https://github.com/ashfurrow/Moya/pull/72) ([juhagman](https://github.com/juhagman))

- Reword an awkward sentence in the README's requirements [\#71](https://github.com/ashfurrow/Moya/pull/71) ([interstateone](https://github.com/interstateone))

- Fix for https://github.com/AshFurrow/Moya/issues/66 [\#69](https://github.com/ashfurrow/Moya/pull/69) ([garnett](https://github.com/garnett))

## [0.5](https://github.com/ashfurrow/Moya/tree/0.5) (2014-10-09)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.4...0.5)

**Implemented enhancements:**

- Compile-time check for properties that need to be URL-encoded [\#61](https://github.com/ashfurrow/Moya/issues/61)

**Fixed bugs:**

- Extraneous println [\#53](https://github.com/ashfurrow/Moya/issues/53)

**Closed issues:**

- Inflight Requests are not always being removed [\#63](https://github.com/ashfurrow/Moya/issues/63)

- Alamofire submodule will not update [\#52](https://github.com/ashfurrow/Moya/issues/52)

**Merged pull requests:**

- @orta =\> Inflight fix [\#64](https://github.com/ashfurrow/Moya/pull/64) ([ashfurrow](https://github.com/ashfurrow))

- @ashfurrow =\> Support NSURLResponse introspection in errors [\#62](https://github.com/ashfurrow/Moya/pull/62) ([orta](https://github.com/orta))

- @ashfurrow =\> update to support AlamoFire Xcode 6.1 GM [\#59](https://github.com/ashfurrow/Moya/pull/59) ([orta](https://github.com/orta))

- @ashfurrow =\> xcode 6.1 support [\#58](https://github.com/ashfurrow/Moya/pull/58) ([orta](https://github.com/orta))

- @orta =\> Fixes \#53. [\#55](https://github.com/ashfurrow/Moya/pull/55) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Fixes \#52. [\#54](https://github.com/ashfurrow/Moya/pull/54) ([ashfurrow](https://github.com/ashfurrow))

## [0.4](https://github.com/ashfurrow/Moya/tree/0.4) (2014-09-22)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.3...0.4)

**Merged pull requests:**

- Wrap errors sent with RAC's "sendError" with the appropriate status code, update Sample project to build with new status code requirements [\#50](https://github.com/ashfurrow/Moya/pull/50) ([powerje](https://github.com/powerje))

## [0.3](https://github.com/ashfurrow/Moya/tree/0.3) (2014-09-15)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.2...0.3)

**Implemented enhancements:**

- Make stubbed data responses synchronous [\#48](https://github.com/ashfurrow/Moya/issues/48)

**Merged pull requests:**

- Fixes \#48 [\#49](https://github.com/ashfurrow/Moya/pull/49) ([ashfurrow](https://github.com/ashfurrow))

- Moved test extension into text spec. [\#47](https://github.com/ashfurrow/Moya/pull/47) ([ashfurrow](https://github.com/ashfurrow))

## [0.2](https://github.com/ashfurrow/Moya/tree/0.2) (2014-09-12)

[Full Changelog](https://github.com/ashfurrow/Moya/compare/0.1...0.2)

**Implemented enhancements:**

- Completion blocks should indicate status code or response object [\#44](https://github.com/ashfurrow/Moya/issues/44)

**Merged pull requests:**

- @orta =\> Status codes [\#45](https://github.com/ashfurrow/Moya/pull/45) ([ashfurrow](https://github.com/ashfurrow))

## [0.1](https://github.com/ashfurrow/Moya/tree/0.1) (2014-09-07)

**Implemented enhancements:**

- Sample App [\#39](https://github.com/ashfurrow/Moya/issues/39)

- Switch to returning URL request instead of endpoint in closure [\#37](https://github.com/ashfurrow/Moya/issues/37)

- RACSignal operators for data transformations [\#35](https://github.com/ashfurrow/Moya/issues/35)

- Allow specification of parameter encoding [\#31](https://github.com/ashfurrow/Moya/issues/31)

- Split integration tests into their own testing target [\#26](https://github.com/ashfurrow/Moya/issues/26)

- Logo [\#23](https://github.com/ashfurrow/Moya/issues/23)

- MoyaCompletion object parameter should be NSData [\#22](https://github.com/ashfurrow/Moya/issues/22)

- Provide non-ReactiveCocoa interface [\#16](https://github.com/ashfurrow/Moya/issues/16)

- test network failures [\#15](https://github.com/ashfurrow/Moya/issues/15)

- Incorporate Chris' feedback [\#14](https://github.com/ashfurrow/Moya/issues/14)

- Documentation [\#13](https://github.com/ashfurrow/Moya/issues/13)

- Allow endpoints to specify parsing of data [\#10](https://github.com/ashfurrow/Moya/issues/10)

- Optional, last-minute hook [\#9](https://github.com/ashfurrow/Moya/issues/9)

- Parameters in MoyaEndpointsClosure [\#7](https://github.com/ashfurrow/Moya/issues/7)

- Differentiate GET/POST/etc [\#5](https://github.com/ashfurrow/Moya/issues/5)

- NSURLSessions something something [\#4](https://github.com/ashfurrow/Moya/issues/4)

- Keep track of in-flight requests [\#3](https://github.com/ashfurrow/Moya/issues/3)

- Compile-time safe way to restrict API endpoint calls [\#2](https://github.com/ashfurrow/Moya/issues/2)

- Network API should return a promise or signal or something [\#1](https://github.com/ashfurrow/Moya/issues/1)

**Fixed bugs:**

- Use of RAC is Incorrect [\#19](https://github.com/ashfurrow/Moya/issues/19)

**Closed issues:**

- Make ReactiveCocoa an optional dependency and extension [\#17](https://github.com/ashfurrow/Moya/issues/17)

**Merged pull requests:**

- @orta =\> Fixes \#13. [\#43](https://github.com/ashfurrow/Moya/pull/43) ([ashfurrow](https://github.com/ashfurrow))

- Remove unnecessary framework search paths. [\#42](https://github.com/ashfurrow/Moya/pull/42) ([neonichu](https://github.com/neonichu))

- Shorten checkout instructions. [\#41](https://github.com/ashfurrow/Moya/pull/41) ([neonichu](https://github.com/neonichu))

- @orta =\> Sample app [\#40](https://github.com/ashfurrow/Moya/pull/40) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Fixes \#37. [\#38](https://github.com/ashfurrow/Moya/pull/38) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Signal Operators [\#36](https://github.com/ashfurrow/Moya/pull/36) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Inflight Requests [\#34](https://github.com/ashfurrow/Moya/pull/34) ([ashfurrow](https://github.com/ashfurrow))

- Splits up integration tests into their own target [\#33](https://github.com/ashfurrow/Moya/pull/33) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Header fields [\#32](https://github.com/ashfurrow/Moya/pull/32) ([ashfurrow](https://github.com/ashfurrow))

- @orta =\> Last-minute hook [\#30](https://github.com/ashfurrow/Moya/pull/30) ([ashfurrow](https://github.com/ashfurrow))

- Updated for beta 7, including submodules [\#29](https://github.com/ashfurrow/Moya/pull/29) ([ashfurrow](https://github.com/ashfurrow))

- Typo. [\#28](https://github.com/ashfurrow/Moya/pull/28) ([lipka](https://github.com/lipka))

- logo + readme changes [\#27](https://github.com/ashfurrow/Moya/pull/27) ([orta](https://github.com/orta))

- Fixes \#22. [\#25](https://github.com/ashfurrow/Moya/pull/25) ([ashfurrow](https://github.com/ashfurrow))

- Error samples [\#24](https://github.com/ashfurrow/Moya/pull/24) ([ashfurrow](https://github.com/ashfurrow))

- Adds typesafe routing [\#21](https://github.com/ashfurrow/Moya/pull/21) ([ashfurrow](https://github.com/ashfurrow))

- The 300\_200.png sample image is referring to a location outside the repository [\#20](https://github.com/ashfurrow/Moya/pull/20) ([Thomvis](https://github.com/Thomvis))

- Makes ReactiveCocoa Optional [\#18](https://github.com/ashfurrow/Moya/pull/18) ([ashfurrow](https://github.com/ashfurrow))

- Signals [\#11](https://github.com/ashfurrow/Moya/pull/11) ([ashfurrow](https://github.com/ashfurrow))

- Parameters [\#8](https://github.com/ashfurrow/Moya/pull/8) ([ashfurrow](https://github.com/ashfurrow))

- Abstraction [\#6](https://github.com/ashfurrow/Moya/pull/6) ([ashfurrow](https://github.com/ashfurrow))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*