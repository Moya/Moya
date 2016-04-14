Handle errors with RxSwift
==========================

Sometimes you don't want to add error handling code manually to every
request. Here is extension for `Observable` to add simple error handling:

```swift
extension Observable {
    func showErrorHUD() -> Observable<Element> {
        return self.doOn { event in
            switch event {
            case .Error(let e):
                // Unwrap underlying error
                guard let error = e as? Moya.Error else { throw e }
                guard case .StatusCode(let response) = error else { throw e }
                
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
MyService.request(.ResetPassword(email: textField.text!))
		    .filterSuccessfulStatusCodes()
		    .showErrorHUD()
		    .subscribeNext { response in
		        SVProgressHUD.dismiss()
        
		        showAlert(title: "Your password has been reset.", message: "An email will be sent to you with a new password shortly.")
		    }
```
