# 从版本 10.x 迁移到 11.x

此项目遵循 [语义化版本控制规范](http://semver.org)。

### ReactiveSwift 迁移
- ReactiveSwift的变化内容请查询[ReactiveSwift 3.0.0 发布版本说明](https://github.com/ReactiveCocoa/ReactiveSwift/releases/tag/3.0.0)。

### Endpoint 迁移
- 移除 `Endpoint` 类型的泛型约束，原有的代码“应该”能直接正常运行。

### MoyaProvider 迁移
- 把原有的 `MoyaProvider.defaultEndpointMapping` 更改为 `MoyaProvider<YourType>.defaultEndpointMapping`, `MoyaProvider.defaultRequestMapping` 更改为 `MoyaProvider<YourType>.defaultRequestMapping`, `MoyaProvider.defaultAlamofireManager` 更改为 `MoyaProvider<YourType>.defaultAlamofireManager`.

### Task 迁移
- 添加 `.requestCustomJSONEncodable` 枚举项到 `Task` 或者作为默认枚举项以完善相应的枚举类型.

### TargetType 迁移
- 把 `TargetType` 原有的属性 `validate` 更改为新属性 `validationType`。
如果原有的 `validate` 值是 `false`，则使用 `ValidationType.none` 代替。如果值是 `true` 则使用 `ValidationType.successCodes` 代替。此属性默认值为 `ValidationType.none`。
