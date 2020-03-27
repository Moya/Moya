# Migration Guide from 14.x to 15.x

This project follows [Semantic Versioning](http://semver.org).

### Stubbing Migration
In Moya 14 stubbing had to be set a different places:
- providing  the stubbed data with `TargetType.sampleData`
- providing a `StubBehavior` with `MoyaProvider.stubClosure`
- builder an `Endpoint` using a  custom `EndpointSampleResponse` in `MoyaProvider.endpointClosure`

Those 3 different steps were making stubbing difficult to implement and to maintain.

In Moya 15 stubbing is to be done in only one place.
`TargetType.sampleData` and `MoyaProvider.stubClosure` have been removed in favor of the new `PluginType.stubBehavior(for:)`.
`StubBehavior` and `EndpointSampleResponse` have fusioned together so that `StubBehavior` describes the result to be received and the delay with which it will be received.
