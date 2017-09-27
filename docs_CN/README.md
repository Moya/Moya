# 文档

在您的应用中，Moya从事于高层抽象的工作.
它通过以下管道实现了这一点.

![Pipeline](https://raw.github.com/Moya/Moya/master/web/pipeline.png)

----------------

<p align="center">
    <a href="Targets.md">Targets</a> &bull; <a href="Endpoints.md">Endpoints</a> &bull; <a href="Providers.md">Providers</a> &bull; <a href="Authentication.md">Authentication</a> &bull; <a href="ReactiveSwift.md">ReactiveSwift</a> &bull; <a href="RxSwift.md">RxSwift</a> &bull; <a href="Threading.md">Threading</a> &bull; <a href="Plugins.md">Plugins</a>
</p>

----------------

你不应用直接引用Alamofire. 虽然它是一个很棒的库,但是Moya的观点是你不必处理那些低级的细节。.

(如果你需要使用Alamofire, 你可以传递一个 `SessionManager` 对象实例给到
`MoyaProvider` 构造器.)

如果你想改变Moya的行为，库中可能已经有一种在不修改库的情况下来达到你的目的方法。Moya被设计的超级灵活且满足了每个开发者的需求. 它不是一个实现网络请求的编码性的框架（那是Alamofire的责任），更多的是关于如何考虑网络请求的框架.

记住, 如果在任何时候你有问题, 只要 [open an issue](http://github.com/Moya/Moya/issues/new)
我们会给你一些帮助。
