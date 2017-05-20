RxSwift examples
================

A `RxMoyaProvider` can be created much like a
[`MoyaProvider`](../Providers.md) and can be used as follows:

```swift
let GitHubProvider = RxMoyaProvider<GitHub>()
```

After that simple setup, you're off to the races:

```swift
provider.request(.zen).subscribe { event in
    switch event {
    case .next(let response):
        // do something with the data
    case .error(let error):
        // handle the error
    default:
        break
    }
}
```

Request with filtering successful status codes, JSON parsing and model mapping (with [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper)):

```swift
provider.request(.allUsers)
	.filterSuccessfulStatusCodes()
	.mapJSON()
    .doOn { event in
        guard case Event.next(let element) = event else { return }
        guard let usersCount = element["usersCount"], usersArray = Mapper<User>().mapArray(element["users"]) else { return }

        self.usersCount = usersCount
        self.usersArray = usersArray
    }
    .subscribeNext { results in
        self.tableView.reloadData()
    }
```

Sometimes you don't want to add error handling code manually to every
request. Here is extension for `Observable` to add simple error handling:

```swift
extension Observable {
    func showErrorHUD() -> Observable<Element> {
        return self.doOn { event in
            switch event {
            case .error(let e):
                // Unwrap underlying error
                guard let error = e as? MoyaError else { throw e }
                guard case .statusCode(let response) = error else { throw e }

                // Check statusCode and handle desired errors
                if response.statusCode == 401 {
                    SVProgressHUD.showErrorWithStatus("Please log in again")

                    UserInfo.sharedInstance.invalidate()
                    Router.sharedInstance.popToLoginScreen()
                } else {
                    SVProgressHUD.showErrorWithStatus("Error \(response.statusCode)")
                }

            default: break
            }
        }
    }
}
```

You can see `SVProgressHUD` calls, so in case of error spinner will be
dismissed automatically.

Usage:

```swift
SVProgressHUD.show()
MyService.request(.resetPassword(email: textField.text!))
        .filterSuccessfulStatusCodes()
        .showErrorHUD()
        .subscribeNext { response in
          SVProgressHUD.dismiss()

          showAlert(title: "Your password has been reset.", message: "An email will be sent to you with a new password shortly.")
        }
```
