Creating a custom plugin
=========================================================

As an example of building a custom plugin, let's say we wanted to inform the user about our network activity so we will show an alert view with some basic info about the request as it is being sent, and let users know if a response indicated a failed request (for this example we will also need to assume we dont mind bothering the user with lots of alerts)

First we create a class which will conform to `PluginType`, and accept a reference to a view controller (required to present a `UIAlertController`):

```swift
final class RequestAlertPlugin: PluginType {
    
    private let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func willSendRequest(request: RequestType, target: TargetType) {
        
    }
    
    func didReceiveResponse(result: Result<Response, Error>, target: TargetType) {
        
    }
}
```

Then we add some functionality to the function called when a request will be sent:

```swift
func willSendRequest(request: RequestType, target: TargetType) {
        
        //make sure we have a URL string to display
        guard let requestURLString = request.request?.URL?.absoluteString else { return }
        
        //create alert view controller with a single action
        let alertViewController = UIAlertController(title: "Sending Request", message: requestURLString, preferredStyle: .Alert)
        alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        //and present using the view controller we created at initialisation
        viewController.presentViewController(alertViewController, animated: true, completion: nil)
    }
```

Finally, let's implement `didReceiveResponse` to show an alert if the result was a failure

```swift
func didReceiveResponse(result: Result<Response, Error>, target: TargetType) {
        
        //only continue if result is a failure
        guard case Result.Failure(let error) = result else { return }
        
        //create alert view controller with a single action and messing displaying status code
        let alertViewController = UIAlertController(title: "Error", message: "Request failed with status code: \(error.response?.statusCode ?? 0)", preferredStyle: .Alert)
        alertViewController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        //and present using the view controller we created at initialisation
        viewController.presentViewController(alertViewController, animated: true, completion: nil)
    }
```swift

And that's it, you now have very well informed, if slightly annoyed users.
 
_(Please note that this example will usually fail since presenting an alert twice on the same view controller is not allowed)_
