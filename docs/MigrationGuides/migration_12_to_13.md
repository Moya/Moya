# Migration Guide from 12.x to 13.x

This project follows [Semantic Versioning](http://semver.org).

### TargetType Migration
- Replace the `validate` property of `TargetType` with the new property `validationType`.
If `validate` was previously `false`, use `ValidationType.none`. If `true`, use `ValidationType.successCodes`. The default is `ValidationType.none`.
