import UIKit

class ViewController: UITableViewController {
    var progressView = UIView()
    var repos = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: 0, height: 2))
        progressView.backgroundColor = .blueColor()
        self.navigationController?.navigationBar.addSubview(progressView)
        
        downloadRepositories("ashfurrow")
    }

    // MARK: - API Stuff

    func downloadRepositories(username: String) {
        GitHubProvider.request(.UserRepositories(username), completion: { result in

            var success = true
            var message = "Unable to fetch from GitHub"
            
            switch result {
            case let .Success(response):
                do {
                    let json: NSArray? = try response.mapJSON() as? NSArray
                    if let json = json {
                        // Presumably, you'd parse the JSON into a model object. This is just a demo, so we'll keep it as-is.
                        self.repos = json
                    } else {
                        success = false
                    }
                } catch {
                    success = false
                }
                self.tableView.reloadData()
            case let .Failure(error):
                guard let error = error as? CustomStringConvertible else {
                    break
                }
                message = error.description
                success = false
            }
            
            if !success {
                let alertController = UIAlertController(title: "GitHub Fetch", message: message, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                })
                alertController.addAction(ok)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }

    func downloadZen() {
        GitHubProvider.request(.Zen, completion: { result in
            var message = "Couldn't access API"
            if case let .Success(response) = result {
                message = (try? response.mapString()) ?? message
            }

            let alertController = UIAlertController(title: "Zen", message: message, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
            })
            alertController.addAction(ok)
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func giphyWasPressed(sender: UIBarButtonItem) {
        uploadGiphy()
    }
    
    func uploadGiphy() {
        let data = animatedBirdData()
        GiphyProvider.request(.Upload(gif: data),
            queue: dispatch_get_main_queue(),
            progress: { response in
                UIView.animateWithDuration(0.3) {
                    self.progressView.frame.size.width = self.view.frame.size.width * CGFloat(response.progress)
                }
            },
            completion: { result in
                let color: UIColor
                switch result {
                case .Success:
                    color = .greenColor()
                case .Failure:
                    color = .redColor()
                }
                
                UIView.animateWithDuration(0.3) {
                    self.progressView.backgroundColor = color
                    self.progressView.frame.size.width = self.view.frame.size.width
                }
                UIView.animateWithDuration(0.3, delay: 1, options: [], animations: {
                    self.progressView.alpha = 0
                }, completion: { _ in
                    self.progressView.backgroundColor = .blueColor()
                    self.progressView.frame.size.width = 0
                    self.progressView.alpha = 1
                })
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

