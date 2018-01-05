# Migration Guide from 10.x to 11.x

This project follows [Semantic Versioning](http://semver.org).

### Task Migration
- Add `.requestCustomJSONEncodable` case to `Task` or default case to achieve exhaustiveness.

### TargetType Migration
- Replace the `validate` property of `TargetType` with the new property `validationType`.
If `validate` was previously `false`, use `ValidationType.none`. If `true`, use `ValidationType.successCodes`. The default is `ValidationType.none`.
