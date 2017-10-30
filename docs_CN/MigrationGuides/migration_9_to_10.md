# 从版本 9.x 迁移到 10.x

此项目遵循 [Semantic Versioning](http://semver.org).

### MoyaError 迁移
- 新增了 `.parameterEncoding`, `.objectMapping`, `.encodableMapping`, 需要添加所有的case 或者一个默认的 `default` case 来完备条件.

### Task 迁移
- 新增 `.requestJSONEncodable` case 到 `Task` 或者 默认 case 来完备条件.

### Endpoint 迁移
- 替换先前`Endpoint.init`中 `method`的 默认参数 `.get`.
- 替换先前 `Endpoint.init`中`httpHeaderFields`的默认值 `nil`.
- 替换先前 `Endpoint`的 `urlRequest` 属性，现在使用 `try? urlRequest()` 或者使用 `do/catch` 语法来处理抛出的错误.

### NetworkActivityPlugin 迁移
-  在 `NetworkActivityPlugin` 构造器中添加 `TargetType` 作为 `NetworkActivityClosure`的第二个参数.

### ReactiveCocoa 子模块迁移
- 在您的 Podfile文件中，替换 `pod 'Moya/ReactiveCocoa'` 为 `pod 'Moya/ReactiveSwift'` .
