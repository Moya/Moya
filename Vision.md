## Project Goals

- leverage the Swift compiler to prevent runtime errors associated with configuring network requests.
- provide a Swift-first API/abstraction for making network requests.
- provide an API that makes it easy to stub network requests.
- provide an API where common things are easy, and uncommon things are possible.
- provide basics of response decoding while exposing customization points for other libraries to help.
- provide (optional) RxSwift / ReactiveSwift extensions to the API.
- avoid leaky abstractions by providing thoughtful and easy-to-use extension points for customizing behaviour.
- favour explicitly-defined behaviour over default implementations.
- cultivate an inclusive open source community through respectful discussion.

## Project Inspiration

The original idea came from a discussion with [Chris Eidhof][chris] about how to leverage the Swift compiler to encapsulate network requests to a Swift `enum`, to provide a high level of compile-time confidence that a network request is properly configured. 

## Moya's Relation to Artsy

Moya began as a part of [Eidolon][eidolon], which was [being developed][blog] in 2014, the days of the Swift 1.0 betas, by [Ash Furrow][ash] and [Orta Therox][orta], working for [Artsy][artsy]. The project was quickly moved to its own library on Ash's GitHub account, and eventually to [its own GitHub organization][org]. Moya is run by a [community of contributors][community], and the code has always been released under the [MIT license][license].


[eidolon]: https://github.com/artsy/eidolon
[blog]: http://artsy.github.io/blog/2014/11/13/eidolon-retrospective/
[ash]: https://github.com/ashfurrow
[orta]: https://github.com/orta
[chris]: https://github.com/chriseidhof
[artsy]: https://artsy.net
[org]: https://github.com/Moya
[license]: https://github.com/Moya/Moya/blob/master/License.md
[community]: https://github.com/Moya/contributors

