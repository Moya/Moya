Documentation
=============

Moya is about working at *high levels of abstraction* in your application.
It accomplishes this with the following pipeline.

![Pipeline](https://raw.github.com/Moya/Moya/master/web/pipeline.png)

----------------

<p align="center">
    <a href="Targets.md">Targets</a> &bull; <a href="Endpoints.md">Endpoints</a> &bull; <a href="Providers.md">Providers</a> &bull; <a href="Authentication.md">Authentication</a> &bull; <a href="ReactiveSwift.md">ReactiveSwift</a> &bull; <a href="RxSwift.md">RxSwift</a> &bull; <a href="Plugins.md">Plugins</a>
</p>

----------------

You _should not_ have to reference Alamofire directly. It's an _awesome_
library, but the point of Moya is that you don't have to deal with details
that are that low-level.

(If you _need_ to use Alamofire, you can pass in a `SessionManager` instance to the
`MoyaProvider` initializer.)

If there is something you want to change about the behaviour of Moya, there is
probably a way to do it without modifying the library. Moya is designed to be
super-flexible and accommodate the needs of every developer. It's less of a
framework _of code_ and more of a framework of _how to think_ about network
requests.

Remember, if at any point you have a question, just [open an issue](http://github.com/Moya/Moya/issues/new)
and we'll get you some help.
