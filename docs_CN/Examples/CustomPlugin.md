# 创建自定义的插件

作为构建一个自定义的插件的示例，假设我们想把网络活动通知给用户，那么当请求被发送时，我们将显示携有关于请求的基本信息的提示框，并且当一个响应表明这个请求失败时让用户知道 (对于这个例子，我们还需要假设我们不介意用大量的提示框来打扰用户)

首先，我们需要创建一个遵循  `PluginType`的类, 并且它接收一个视图控制器 (用来展示 `UIAlertController`)的实例对象的引用:

```swift
final class RequestAlertPlugin: PluginType {

    private let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func willSend(_ request: RequestType, target: TargetType) {

    }

    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {

    }
}
```

然后，当请求将被发送时，我们向函数添加一些功能:

```swift
func willSend(_ request: RequestType, target: TargetType) {

    //make sure we have a URL string to display
    guard let requestURLString = request.request?.url?.absoluteString else { return }

    //create alert view controller with a single action
    let alertViewController = UIAlertController(title: "Sending Request", message: requestURLString, preferredStyle: .alert)
    alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    //and present using the view controller we created at initialization
    viewController.present(viewControllerToPresent: alertViewController, animated: true)
}
```

最后, 如果结果出错了，让我们在 `didReceive` 中实现一个提示框 

```swift
func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {

    //only continue if result is a failure
    guard case Result.failure(_) = result else { return }

    //create alert view controller with a single action and messing displaying status code
    let alertViewController = UIAlertController(title: "Error", message: "Request failed with status code: \(error.response?.statusCode ?? 0)", preferredStyle: .alert)
    alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    //and present using the view controller we created at initialization
    viewController.present(viewControllerToPresent: alertViewController, animated: true)
}
```

到此完毕, you now have very well informed, if slightly annoyed users.

_(Please note that this example will usually fail since presenting an alert twice on the same view controller is not allowed)_
