# 迁移向导

此项目遵循[Semantic Versioning](http://semver.org).

当**更新到Moya的一个新的主版本时**请遵循下面的适当引导 (例如. 8.0 -> 9.0).

## 从 8.x 到 9.x的更新

### TargetType 迁移
- 移动 `parameters` 和 `parameterEncoding` 到 `task` 计算属性的 case `.requestParameters(parameters:encoding:)`中
- 替换 task 类型的值 `.request` 为 `.requestPlain` (如果没有参数) 或者 `.requestParameters(parameters:encoding:)`
- Endpoints不再有 `parameters` 和 `parameterEncoding` (比如. `addingParameters()`), 现在使用新的 `task` 属性来替代
- 发送URL编码参数和body参数, 您现在可以使用task 类型 `.requestCompositeParameters(bodyParameters:bodyEncoding:urlParameters:)`
- 简化任务类型 `.download(.request(destination))` 为 `.downloadDestination(destination)`
- 简化任务类型 `.upload(.file(url))` 为 `.uploadFile(url)`
- 简化任务类型 `.upload(.multipart(data))` 为 `.uploadMultipart(data)`

### AccessTokenPlugin 迁移
- 使用`AccessTokenPlugin`给`TargetType`添加了`AccessTokenAuthorizable`一致性.
- 如果`shouldAuthorize` 为 `true` 或者未定义，指定一个值为 `.bearer`的`AuthorizationType` 。

### Reactive MoyaProvider  迁移
- 替换 `RxMoyaProvider<Target>` 为 `MoyaProvider<Target>` 并使用 `.rx` 命名空间来访问 RxSwift API.
- 替换 `ReactiveMoyaProvider<Target>` 为 `MoyaProvider<Target>` 并使用 `.reactive` 命名空间来访问 ReactiveSwift API.
- 如果您要创建一个reactive provider子类, 查看这个PR [Eidolon's migration to Moya 9.0.0](https://github.com/artsy/eidolon/pull/669) 它讲述了从子类化到组合的迁移。 
