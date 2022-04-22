## 项目目标

- 利用 Swift 编译器来避免与配置网络请求相关的运行时错误。
- 为网络请求提供 Swift 风格的 API或抽象。
- 提供一个 API，它可以非常容易来记录网络请求。
- 提供一个 API，让常见需求更加容易被实现，也让不可能成为可能。
- 提供基本的响应解析能力，同时也保留面向第三方库的可扩展性。
- 为 API 提供 (可选的) `RxSwift/ReactiveSwift` 扩展。
- 通过为自定义行为提供周到且易于使用的扩展能力来避免有漏洞的抽象。
- 偏向明确定义的行为胜过默认实现。
- 通过相互尊重的讨论，培养一个包容性的开源社区。

## 项目灵感

最初的想法来自于与 [Chris Eidhof](https://github.com/chriseidhof) 讨论如何利用 Swift 编译器来把网络请求封装到 Swift 的 `enum` 中，能确保在编译时就能确认网络请求是否被正确配置。 

## Moya 与 Artsy 的关系

Moya 起源于 [Eidolon](https://github.com/artsy/eidolon) 项目，这个项目是在 2014 年由当时还就职于 [Artsy](https://artsy.net/) 的 [Ash Furrow](https://github.com/ashfurrow)和 [Orta Therox](https://github.com/orta) 开发的，那时 Swift 刚刚处于 1.0 的 beta 阶段。这个项目很快被移到 Ash 的 GitHub 中，然后最终移到了 [Moya自己的 GitHub 组织](https://github.com/Moya) 下。Moya 是由[社区的贡献者](https://github.com/Moya/contributors)来维护的，代码一直使用在[MIT许可](https://github.com/Moya/Moya/blob/master/License.md)下进行发布。

