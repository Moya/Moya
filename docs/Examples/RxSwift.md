RxSwift examples
================

A `RxMoyaProvider` can be created much like a
[`MoyaProvider`](Providers.md) and can be used as follows:

```swift
let GitHubProvider = RxMoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
provider.request(.Zen).subscribe { (event) -> Void in
    switch event {
    case .Next(let response):
        // do something with the data
    case .Error(let error):
        // handle the error
    default:
        break
    }
}
```

Request with filtering successful status codes, JSON parsing and model mapping (with [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper)):

```swift
provider.request(.AllUsers)
	.filterSuccessfulStatusCodes()
	.mapJSON()
    .doOn { event in
        guard case Event.Next(let element) = event else { return }
		guard let usersCount = element["usersCount"], usersArray = Mapper<User>().mapArray(element["users"]) else { return }
		
        self.usersCount = usersCount
		self.usersArray = usersArray
    }
    .subscribeNext { results in
        self.tableView.reloadData()
    }
```
