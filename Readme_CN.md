<p align="center">
  <img height="160" src="web/logo_github.png" />
</p>

# Moya

[![CircleCI](https://img.shields.io/circleci/project/github/Moya/Moya/master.svg)](https://circleci.com/gh/Moya/Moya/tree/master)
[![codecov.io](https://codecov.io/github/Moya/Moya/coverage.svg?branch=master)](https://codecov.io/github/Moya/Moya?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/Moya.svg)](https://cocoapods.org/pods/Moya)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

你是个聪明的开发者。你可能使用 [Alamofire](https://github.com/Alamofire/Alamofire) 来抽象对 `URLSession` 的访问，以及所有那些你并不关心的糟糕细节。但是接下来，就像许多聪明开发者一样，你编写专有的网络抽象层，它们可能被称作 "APIManager" 或 "NetworkModel"，它们的下场总是很惨。

![Moya Overview](web/diagram.png)

在 iOS app 中，专有网络层非常常见，但它们有以下缺点：

- 编写新项目很困难（「我从哪儿开始呢？」）
- 维护现有的项目很困难（「天啊，这一团糟……」）
- 编写单元测试很困难（「我该怎么做呢？」）

所以 Moya 的基本思想是，提供一些网络抽象层，它们经过充分地封装，并直接调用 Alamofire。它们应该足够简单，可以很轻松地应对常见任务，也应该足够全面，应对复杂任务也同样容易。

> 如果你使用 Alamofire 来抽象 `URLSession`, 那为什么不使用某些方式来进一步抽象 URLs 和 parameters 等等的本质呢？

Moya 的一些特色功能：

- 编译时检查正确的 API 端点访问。
- 允许你使用枚举关联值定义不同端点的明确用法。
- 将 test stub 视为一等公民，所以单元测试超级简单。

你可以在 [愿景文档](https://github.com/Moya/Moya/blob/master/Vision_CN.md) 中查看更多关于项目方向的信息。

## 示例项目

我们在仓库中提供了两个示例项目。要使用它，请下载仓库，运行 `carthage update` 下载所需的库，然后打开 [Moya.xcodeproj]（https://github.com/Moya/Moya/tree/master/Moya.xcodeproj）。你会看到两个 scheme：`Basic` 和 `Multi-Target` ——选择一个然后构建并运行！这些源文件位于项目导航的 `Examples` 目录中。玩得开心！

## 项目状态

这个项目正在积极地开发中，并且它正被用于 [Artsy 的新拍卖应用](https://github.com/Artsy/eidolon)。我们认为它已经可以用于生产了。

## 安装

### Moya 版本 vs Swift 版本

下边的表格展示了 Moya 版本与其对应的 Swift 版本。

| Swift | Moya           | RxMoya          | ReactiveMoya   |
| ----- | -------------- |---------------- |--------------- |
| 5.X   | >= 13.0.0      | >= 13.0.0       | >= 13.0.0      |
| 4.X   | 9.0.0 - 12.0.1 | 10.0.0 - 12.0.1 | 9.0.0 - 12.0.1 |
| 3.X   | 8.0.0 - 8.0.5  | 8.0.0 - 8.0.5   | 8.0.0 - 8.0.5  |
| 2.3   | 7.0.2 - 7.0.4  | 7.0.2 - 7.0.4   | 7.0.2 - 7.0.4  |
| 2.2   | <= 7.0.1       | <= 7.0.1        | <= 7.0.1       |

**升级到 Moya 的最新主版本？查看我们的 [迁移向导](https://github.com/Moya/Moya/blob/master/docs_CN/MigrationGuides)**。

### Swift Package Manager

要使用苹果的 Swift Package Manager 集成，将以下内容作为依赖添加到你的 `Package.swift`：

```swift
.package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "13.0.0"))
```

然后指定 `"Moya"` 为你想要使用 Moya 的 Target 的依赖。如果你想要使用响应式扩展，将 `"ReactiveMoya"` 和 `"RxMoya"` 也也作为依赖加入进来。这里是一个 `PackageDescription` 实例：

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MyPackage",
    products: [
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "13.0.0"))
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: ["ReactiveMoya"])
    ]
)
```

注意从 Moya 10 开始，SPM 仅适用于 Swift 4 与更高版本的工具链。

### CocoaPods

在你的 Podfile 文件中添加 Moya：

```rb
pod 'Moya', '~> 13.0'

# or 

pod 'Moya/RxSwift', '~> 13.0'

# or

pod 'Moya/ReactiveSwift', '~> 13.0'
```

然后运行 `pod install`。

在任何你想使用 Moya 的文件中，使用 `import Moya` 导入框架。

### Carthage

Carthage 用户可以指向这个仓库并使用他们喜欢的生成框架，`Moya`，`RxMoya` 或者 `ReactiveMoya`。

在你的 Cartfile 中添加下面的代码：

```
github "Moya/Moya" ~> 13.0
```

然后运行 `carthage update`。

如果这是你首次在项目中使用 Carthage，你将需要进行一些额外的步骤，它们在 [Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) 中有解释。

> 注意：目前，Carthage 没有提供仅构建特定仓库子模块的方法。使用上述命令将构建所有子模块及其依赖项。但是，你不必将不使用的框架复制到项目中。例如，如果您没有使用 ReactiveSwift，请在 `carthage update` 完成后随意从 Carthage 的构建目录中删除框架 ReactiveMoya。或者如果你使用的是 ReactiveSwift 而不是 RxSwift，则可以安全地删除 RxMoya，RxTest，RxCocoa 等。

### 手动

- 打开终端，`cd` 到你项目的顶层目录，如果你的项目没有初始化为 git 仓库，运行下面的命令：

```bash
$ git init
```

- 通过运行以下命令来添加 Alamofire，Result & Moya 作为 git [submodule](http://git-scm.com/docs/git-submodule)：

```bash
$ git submodule add https://github.com/Alamofire/Alamofire.git
$ git submodule add https://github.com/antitypical/Result.git
$ git submodule add https://github.com/Moya/Moya.git
```

- 打开新建的 `Alamofire` 文件夹，把 `Alamofire.xcodeproj` 拖拽到你 XCode 的项目导航中。对 Result 文件夹下的 `Result.xcodeproj` 和 Moya 文件夹下的 `Moya.xcodeproj` 做同样的操作。

> 它们应该嵌套在应用程序的蓝色项目图标下面，在其它 Xcode group 的上面或者下面都没关系。

- 验证 `xcodeproj` 的部署 target 与你项目导航中的应用程序 target 一致。
- 接下来，在项目导航（蓝色的项目图标）中选择你的应用项目然后导航到 target 配置窗口，并且在侧栏中的 Targets 标题下选择应用程序 target。
- 在窗口顶部的标签栏中，打开 "General" 面板。
- 点击 "Embedded Binaries" 区域下面的 `+` 按钮。
- 你将会看到两个不同的 `Alamofire.xcodeproj` 文件夹。每个文件夹都有两个不同版本的 `Alamofire.framework` 嵌套在 `Products` 文件夹里。

> 选择哪个 `Products` 文件夹并不重要，重要的是你选择的是上边的还是下边的 `Alamofire.framework`。

- 为 iOS 选择上边的 `Alamofire.framework`，下边的用于 macOS。

> 你可以通过检查项目的构建日志来验证你选择的是哪一个。`Alamofire` 的 build target 将被列为 `Alamofire iOS`, `Alamofire macOS`, `Alamofire tvOS` 或 `Alamofire watchOS`。

- 点击 "Embedded Binaries" 下面的 `+` 按钮，为 `Result` 添加你需要的 build target。
- 再次点击 `+` 按钮为 `Moya` 添加正确的 build target。

- 这就完事了！

> 这三个框架会作为 target dependency，linked framework 和 embedded framework 被自动添加到一个 copy files build phase，这就是在模拟器和设备进行构建所需要的全部内容了。

## 用法

经过 [一些设置](https://github.com/Moya/Moya/blob/master/docs_CN/Examples/Basic.md) 后，使用 Moya 相当简单。你可以用下边的方式访问一个 API：

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

这个一个基本示例。很多 API 请求都需要参数。Moya 将参数编码到 enum 中来访问端点，如下所示：

```swift
provider = MoyaProvider<GitHub>()
provider.request(.userProfile("ashfurrow")) { result in
    // do something with the result
}
```

URLs 不再有书写错误。不再会缺失参数值。也不再有混乱的参数编码。

更多示例可以查看 [documentation](https://github.com/Moya/Moya/blob/master/docs_CN/Examples)。

## Reactive 扩展

更酷的是响应式扩展。Moya 为 [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) 和 [RxSwift](https://github.com/ReactiveX/RxSwift) 提供了响应式扩展。

### ReactiveSwift

[`ReactiveSwift` extension](https://github.com/Moya/Moya/blob/master/docs_CN/ReactiveSwift.md) 提供了 `reactive.request(:callbackQueue:)` 和 `reactive.requestWithProgress(:callbackQueue:)` 两种立即返回 `SignalProducer` 对象的方法，你可以 start，bind，map 或做任何你想做的。

对于错误处理，举例来说，我们可以像下面这样处理：

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

[`RxSwift` extension](https://github.com/Moya/Moya/blob/master/docs_CN/RxSwift.md) 也提供了 `rx.request(:callbackQueue:)` 和 `rx.requestWithProgress(:callbackQueue:)` 两种方法，但是这两个方法返回类型不一样。`rx.request(:callbackQueue)` 的返回类型是 `Single<Response>`，它只会发送单个元素或者一个错误。`rx.requestWithProgress(:callbackQueue:)` 的返回类型是 `Observable<ProgressResponse>`，因为我们可能从进度中获取多次事件以及作为响应的最后一次事件。

对于错误处理，举例来说，我们可以像下面这样处理：

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

除了使用信号而不是回调闭包之外，RxSwift 和 ReactiveSwift 还有一系列信号操作符，它们可以把从网络响应接收到的数据分别通过 `mapImage()`，`mapJSON()` 以及 `mapString()` 映射成一个图片、一些 json 或者一个字符串。如果映射不成功，你会从信号中得到一个错误。你还可以使用一些方便的方法来过滤某些状态码。这意味着你可以将处理 API 错误（比如 400）的代码与处理无效响应的代码写在相同的位置。

## 社区项目

[Moya 有一个很棒的社区，有些人已经创建了一些非常有用的扩展。](https://github.com/Moya/Moya/blob/master/docs_CN/CommunityProjects.md)

## 贡献

嗨！你喜欢 Moya 吗？非常棒！我们的确需要你的帮助！

开源不仅仅是写代码。Moya 可以在以下几个方面需要你的帮助：

- 发现（报告！）bugs。
- 新功能建议。
- 在 issues 上回答问题。
- 文档的改进。
- 审查 pull requests。
- 帮助管理 issues 优先级。
- 修复 bug / 新功能。

如果你对其中任何一个感兴趣，请发送一个请求！经过几轮贡献，我们会把你作为管理员添加到 repo 中，这样你就可以合并 pull 请求并且帮助驾驶这艘船 🚢。你可以在我们的 [贡献指南](https://github.com/Moya/Moya/blob/master/Contributing.md) 中阅读更多详情。

Moya 社区拥有巨大的正能量，同时维护人员致力于让事情变得更棒。像 [CocoaPods](https://github.com/CocoaPods/CocoaPods/wiki/Communication-&-Design-Rules) 一样，总是提取积极的意图；即使某个评论听起来非常刻薄，它仍会让人从怀疑中受益。

请注意，这个项目与 Contributor Code of Conduct 一起发布。为了参与到这个项目中来，你需要遵守它的 [条款](https://github.com/Moya/Moya/blob/master/Code%20of%20Conduct_CN.md)。

### 新增源文件

如果你从 Moya 添加或者移除一个源文件，仓库的根目录的 Moya.xcodeproj 也需要作出相应的改变。这个项目要用于 Carthage。但是别担心，如果你提交请求时忘了，会收到一个自动的警告。

### 帮助我们改进 Moya 文档

无论你是核心成员还是用户，你可以通过改进文档对 Moya 做出重大的贡献。如何帮助我们：

- 向我们发送有关你认为令人困惑或缺少的意见
- 建议更好的措辞或解释某些功能的方法
- 通过 GitHub 向我们发送 pull requests
- 改进 [中文文档](https://github.com/Moya/Moya/blob/master/Readme_CN.md)

## 许可证

Moya 是在 MIT license 下发布的。更多信息可以查看 [License.md](https://github.com/Moya/Moya/blob/master/License.md)。
