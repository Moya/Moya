# 对资源下载进行配置

这里我们将会向你展示一个如何为资源下载进行简单的配置的示例。
首先, 让我们来创建一个新的 `TargetType` 实现:

```swift
fileprivate let assetDir: URL = {
  let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return directoryURLs.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
}()

enum Asset: TargetType {
  case star
  case checkmark

  var baseURL: URL { /* ... */ }

  var assetName: String {
    switch self {
    case .star: return "star.png"
    case .checkmark: return "checkmark.png"
    }
  }

  var path: String { "/assets/" + assetName }

  var localLocation: URL { assetDir.appendingPathComponent(assetName) }

  var downloadDestination: DownloadDestination {
      return { _, _ in (self.localLocation, .removePreviousFile) }
  }

  var task: Task { .downloadDestination(downloadDestination) }

  /*
    Rest of TargetType
  */
}
```

然后 使用 `AssetLoader`类来包装 `MoyaProvider`:

```swift
final class AssetLoader {
  let provider = MoyaProvider<Assets>()

  init() { }

  func load(asset: Asset, completion: ((Result<URL, MoyaError>) -> Void)? = nil) {
    if FileManager.default.fileExists(atPath: asset.localLocation.path) {
      completion?(.success(asset.localLocation))
      return
    }

    provider.request(asset) { result in 
      switch result {
      case .success:
        completion?(.success(asset.localLocation))
      case let .failure(error):
        return completion?(.failure(error))
      }
    }
  }
}
```

到此完毕! 为了使用它, 现在你需要创建一个 `AssetLoader` 实例对象然后像下面这样来调用`load()`：


```swift
final class TestViewModel {
    let loader: AssetLoader

    init(loader: AssetLoader = AssetLoader()) {
        self.loader = loader
    }

    func loadImage() {
        loader.load(asset: .star) { result in
            // handle the result
        }
    }
}
```