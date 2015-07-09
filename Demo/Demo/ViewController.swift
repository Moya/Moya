import UIKit

class ViewController: UITableViewController {
    var repos = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()

        downloadRepositories("ashfurrow")
    }

    // MARK: - API Stuff

    func downloadRepositories(username: String) {
        GitHubProvider.request(.UserRepositories(username), completion: { (data, status, resonse, error) -> () in
            var success = error == nil
            if let data = data {
                do {
                    let json: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                    if let json = json as? NSArray {
                        // Presumably, you'd parse the JSON into a model object. This is just a demo, so we'll keep it as-is.
                        self.repos = json
                    } else {
                        success = false
                    }
                } catch {
                    success = false
                }

                self.tableView.reloadData()
            } else {
                success = false
            }

            if !success {
                let alertController = UIAlertController(title: "GitHub Fetch", message: error?.description, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                })
                alertController.addAction(ok)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }

    func downloadZen() {
        GitHubProvider.request(.Zen, completion: { (data, status, response, error) -> () in
            var message = "Couldn't access API"
            if let data = data {
                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String ?? message
            }

            let alertController = UIAlertController(title: "Zen", message: message, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
            })
            alertController.addAction(ok)
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }

    // MARK: - User Interaction

    @IBAction func searchWasPressed(sender: UIBarButtonItem) {
        var usernameTextField: UITextField?

        let promptController = UIAlertController(title: "Username", message: nil, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            if let usernameTextField = usernameTextField {
                self.downloadRepositories(usernameTextField.text!)
            }
        })
        _ = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
        }
        promptController.addAction(ok)
        promptController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            usernameTextField = textField
        }
        presentViewController(promptController, animated: true, completion: nil)
    }

    @IBAction func zenWasPressed(sender: UIBarButtonItem) {
        downloadZen()
    }

    // MARK: - Table View

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let object = repos[indexPath.row] as! NSDictionary
        (cell.textLabel as UILabel!).text = object["name"] as? String
        return cell
    }
}

