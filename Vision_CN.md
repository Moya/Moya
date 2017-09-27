## 项目目标

- 利于Swift 编译器来防止与配置网络请求相关的运行时错误 .
- 为网络请求提供 Swift风格API/抽象.
- 提供一个API，它可以非常容易来代理(stub)网络请求.
- 提供一个基本的响应解析，同时也为其他库公开定制点来提供帮助.
- 为API提供 (可选的) RxSwift / ReactiveSwift 扩展.
- 通过为自定义行为提供周到且易于使用的扩展的点来避免有漏洞的抽象。
- 赞同明确定义的行为胜过默认实现.
- 通过相互尊重的讨论，培养一个包容性的开源社区.

## 项目灵感

最初的想法来自于与 [Chris Eidhof][chris] 讨论如何利用 Swift编译器来把网络请求封装到Swift的 `enum`中, 且提供一个高层次的在编译时就能确认网络请求被配置无误。 

## Moya与 Artsy的关系

Moya 起源于 [Eidolon][eidolon]项目, 这个项目是在2014年被 [Ash Furrow][ash]和 [Orta Therox][orta]开发的 ,那时是Swift 1.0 betas, 他们就职于[Artsy][artsy]. 这个项目很快被移到 Ash's GitHub的库中, 然后最终移到了 [Moya自己的 GitHub 组织][org]. Moya 由 [community of contributors][community]来运行, 并且一直在[MIT license][license]许可下发布的代码 .


[eidolon]: https://github.com/artsy/eidolon
[blog]: http://artsy.github.io/blog/2014/11/13/eidolon-retrospective/
[ash]: https://github.com/ashfurrow
[orta]: https://github.com/orta
[chris]: https://github.com/chriseidhof
[artsy]: https://artsy.net
[org]: https://github.com/Moya
[license]: https://github.com/Moya/Moya/blob/master/License.md
[community]: https://github.com/Moya/contributors

