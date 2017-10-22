<p align="center">
  <img height="160" src="web/logo_github.png" />
</p>

# Moya

[![CircleCI](https://img.shields.io/circleci/project/github/Moya/Moya/master.svg)](https://circleci.com/gh/Moya/Moya/tree/master)
[![codecov.io](https://codecov.io/github/Moya/Moya/coverage.svg?branch=master)](https://codecov.io/github/Moya/Moya?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/Moya.svg)](https://cocoapods.org/pods/Moya)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

您是个聪明的开发者. 您可能使用 [Alamofire](https://github.com/Alamofire/Alamofire) 来抽象访问
`URLSession` ，以及所有那些您并不真正关心的糟糕细节。 但是,
就像许多聪明开发者一样, 您编写专有的网络抽象层. 它们可能被称作 "APIManager" 或者 "NetworkModel", 并且它们总是以眼泪结束。
![Moya Overview](web/diagram.png)

在iOS App中，专有网络层非常常见. 但它们有以下缺点:

- 编写新项目很困难 ("我从哪儿开始呢?")
- 维护现有的项目很困难 ("天啊, 这一团糟...")
- 编写单元测试很困难 ("我该怎么做呢?")

所以，Moya的基本思想是，提供一些网络抽象层，它们被充分的封装了且实际上直接调用了Alamofire. 它不仅在普通的简单的事情上很容易使用，而且在综合的复杂的事情上也容易使用

> 如果你使用 Alamofire 来抽象 `URLSession`, 那为什么不使用一些方式来抽象URLs和parameters等等的本质呢?

Moya的一些特色功能:

- 对正确的API端点访问进行编译时检查.
- 让您使用关联的枚举值定义不同端点的清晰用法.
- 把test stub作为一等公民，所以单元测试超级简单.

您可以在 [愿景文档](Vision_CN.md)中查看更多关于项目方向的信息

## 示例项目

在Demo 文件夹下有个示例项目. 为了使用它, 运行 `pod install` 来下载需要的库. 玩得开心!

## 项目状态

这个项目正在积极的开发中, 并且它正被用于 [Artsy's
new auction app](https://github.com/Artsy/eidolon). 我们认为它已经可以用于生产了。


## 安装

### Moya 版本 vs Swift 版本.

下面显示了Moya版本与其对应的Swift版本.

| Swift | Moya          | RxMoya        | ReactiveMoya  |
| ----- | ------------- |---------------|---------------|
| 4.X   | >= 9.0        | >= 10.0       | >= 9.0        |
| 3.X   | 8.0.0 - 8.0.5 | 8.0.0 - 8.0.5 | 8.0.0 - 8.0.5 |
| 2.3   | 7.0.2 - 7.0.4 | 7.0.2 - 7.0.4 | 7.0.2 - 7.0.4 |
| 2.2   | <= 7.0.1      | <= 7.0.1      | <= 7.0.1      |

**升级到Moya的最新主版本? 查看我们的 [迁移向导](https://github.com/Moya/Moya/blob/master/docs_CN/MigrationGuides.md).**

### Swift 包管理器

要集成使用苹果的Swift包管理器，请将以下内容作为依赖项添加到`Package.swift`:

```swift
.package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "10.0.0"))
```

然后指定 `.Target(name: "Moya")` 使用Moya的依赖项.
这里有个例子 `PackageDescription`:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "10.0.0"))
    ]
)
```

### CocoaPods

在您的Podfile文件中使用Moya:

```rb
pod 'Moya'

# or 

pod 'Moya/RxSwift'

# or

pod 'Moya/ReactiveSwift'
```

然后运行 `pod install`.

在任何您想使用Moya的文件中，请导入框架，通过 `import Moya`.

### Carthage

Carthage 用户可以指向这个仓库并且使用他们想要的任何一个生成的框架, `Moya`, `RxMoya`, 或者 `ReactiveMoya`.

在你的Cartfile中添加下面的代码:

```
github "Moya/Moya"
```

然后运行 `carthage update`.

如果这是你首次在项目中使用Carthage ，那么你需要进行一些额外的步骤，它们在 [over at Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)中有解释.

### 手动

- 打开 Terminal, `cd` 到您项目的顶层目录, 如果您的项目没有初始化git作为仓库，然后运行下面的命令:

```bash
$ git init
```

- 通过运行以下命令来添加Alamofire, Result & Moya 作为git子模块 [submodule](http://git-scm.com/docs/git-submodule) :

```bash
$ git submodule add https://github.com/Alamofire/Alamofire.git
$ git submodule add https://github.com/antitypical/Result.git
$ git submodule add https://github.com/Moya/Moya.git
```

- 打开新建的 `Alamofire` 文件夹, 并且把 `Alamofire.xcodeproj` 拖拽到你XCode项目中的Project Navigator 里. 对Result文件夹下的 `Result.xcodeproj` 和Moya文件夹下的 `Moya.xcodeproj` 做同样的操作.

> 它们应该嵌套在应用程序的蓝色项目图标下面. 对于它们是在其他Xcode组的上面或者下面这都没关系.

- 核查xcodeprojs的部署目标与你项目导航器中的应用程序目标一致.
- 下一步, 在Project Navigator（蓝色的项目图标）中选择你的应用项目然后导航到target配置窗口，并且在侧栏中的“Targets”标题下选择应用程序目标.
- 在窗口顶部的标签栏中，打开"General"面板。
- 在 "Embedded Binaries"区域的下面点击 `+`按钮 .
- You will see two different `Alamofire.xcodeproj` folders each with two different versions of the `Alamofire.framework` nested inside a `Products` folder.

> It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `Alamofire.framework`.

- 为iOS选择顶部的 `Alamofire.framework` ，下面的是用于OS X的.

> You can verify which one you selected by inspecting the build log for your project. The build target for `Alamofire` will be listed as either `Alamofire iOS`, `Alamofire macOS`, `Alamofire tvOS` or `Alamofire watchOS`.

- 点击  "Embedded Binaries" 下面的`+` 按钮 为`Result`添加你需要的构建目标 .
- 再次点击 `+` 按钮为`Moya`添加正确的构建目标.

- 这就完事了!

> The three frameworks are automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

## 用法

在 [一些设置](docs/Examples/Basic.md)之后, 使用Moya相当的简单。 您可以像下面的方式访问API:

```swift
provider = MoyaProvider<GitHub>()
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode
        // do something with the response data or statusCode
    case let .failure(error):
        // this means there was a network failure - either the request
        // wasn't sent (connectivity), or no response was received (server
        // timed out).  If the server responds with a 4xx or 5xx error, that
        // will be sent as a ".success"-ful response.
    }
}
```

这个一个基本的示例。 很多API请求都需要参数。 Moya将参数编码到enum中，来访问端点，就像这样:

```swift
provider = MoyaProvider<GitHub>()
provider.request(.userProfile("ashfurrow")) { result in
    // do something with the result
}
```

URLs不在有书写错误.参数值不在有缺失. 混乱的参数编码也不在有.

更多示例，查看 [documentation](docs_CN/Examples).

## Reactive 扩展

更酷的是响应式扩展。 Moya 为
[ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) 和
[RxSwift](https://github.com/ReactiveX/RxSwift)提供了响应式扩展.

### ReactiveSwift

[`ReactiveSwift` extension](docs/ReactiveSwift.md) 提供了 `reactive.request(:callbackQueue:)` 和 
`reactive.requestWithProgress(:callbackQueue:)` 两种立即返回  
`SignalProducer`对象的方法 ，你可以start, bind, map, 或任何你想做的. 

为了处理错误, 比如, 我们可以像下面这样处理:

```swift
provider = MoyaProvider<GitHub>()
provider.reactive.request(.userProfile("ashfurrow")).start { event in
    switch event {
    case let .value(response):
        image = UIImage(data: response.data)
    case let .failed(error):
        print(error)
    default:
        break
    }
}
```

### RxSwift

[`RxSwift` extension](docs/RxSwift.md) 也提供了 `rx.request(:callbackQueue:)` 和 
`rx.requestWithProgress(:callbackQueue:)` 两种方法, 但是这两个方法返回类型完全不一样. 在正常情况下 `rx.request(:callbackQueue)`, 返回类型是 `Single<Response>` ，它要么发送单个元素要么发送一个错误。而 `rx.requestWithProgress(:callbackQueue:)`, 返回类型是 `Observable<ProgressResponse>`, 因为我们可能从进度中获取多个事件和响应的最后一个事件。

为了处理错误, 例如, 我们可以像下面这样处理:

```swift
provider = MoyaProvider<GitHub>()
provider.rx.request(.userProfile("ashfurrow")).subscribe { event in
    switch event {
    case let .success(response):
        image = UIImage(data: response.data)
    case let .error(error):
        print(error)
    }
}
```

除了使用信号而不是回调闭包之外，还有RxSwift和ReactiveSwift的一系列信号操作符，它们可以把从网络响应接收到的数据映分别通过`mapImage()`, `mapJSON()`, and `mapString()`射成一个图片、一些json或者一个字符串。如果映射不成功，您将会从信号中得到一个错误。您还可以使用一些方便的方法来过滤某些状态码。这意味着您可以将处理API错误（比如400）的代码放置在与处理无效响应代码相同的位置上。

## 社区项目

[Moya有一个很棒的社区，有些人已经创建了一些非常有用的扩展。](https://github.com/Moya/Moya/blob/master/docs/CommunityProjects.md)

## 贡献

嗨! 你喜欢 Moya吗? 非常棒! 我们的确需要您的帮助!

开源不仅仅是写代码. Moya 可以在以下几个方面需要您的帮助:

- 发现 (报告!) bugs.
- 新功能建议.
- 在issues上回答问题.
- 文档的改进.
- 审查 pull requests.
- 帮助管理issues优先级.
- 修复bug /新功能.

如果您对其中任何一个感兴趣，请发送一个请求! 经过几轮贡献, 我们会把您作为管理员添加到repo中，这样您就可以合并pull 请求并且帮助驾驶这艘船:ship: 您可以在 [in our contributor guidelines](https://github.com/Moya/Moya/blob/master/Contributing.md).阅读更多详情

Moya's 社区拥有巨大的正能量, 并且维护人员致力于让事情变得更棒. 像 [in the CocoaPods community](https://github.com/CocoaPods/CocoaPods/wiki/Communication-&-Design-Rules), 总是提取积极的意图; 即使评论听起来非常刻薄, 它会让人从怀疑中受益

请注意，这个项目是用Contributor Code of Conduct发布的. 为了参与到这个项目中来，您需要遵守 [its terms](https://github.com/Moya/Moya/blob/master/Code%20of%20Conduct.md)中条目.

### 新增源文件

如果您从Moya添加或者移除一个源文件, 相应的改变需要在这个仓库的根目录的Moya.xcodeproj中同步. 这个项目要用于Carthage. 但是别担心, 如果你提交请求时忘了，会收到一个自动的警告.

### 帮助我们改进Moya文档

无论您是核心成员还是用户，您可以通过改进文档对Moya做出重大的贡献。如何帮助我们：



 - 向我们发送有关您认为令人困惑或缺少的意见
 - 建议更好的措辞或解释某些功能的方法
 - 通过GitHub向我们发送pull requests
 - 改进[中文文档](Readme_CN.md)


## 许可证

Moya 是在 MIT license下发布的. 更多信息查看 [License.md](License.md) 。
