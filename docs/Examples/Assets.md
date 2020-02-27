# Setup for Assets downloading

Here we will show you how to achieve a simple setup for assets downloading.
First, let's create a new `TargetType` implementation:
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

  var path: String {  "/assets/" + assetName }

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

Then let's wrap `MoyaProvider` with `AssetLoader` class:
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

And that's it! To use it, now you will have to have a retained `AssetLoader` object
and just use `load()` method like:
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