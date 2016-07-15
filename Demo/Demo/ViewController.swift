import UIKit

class ViewController: UITableViewController {
    var progressView = UIView()
    var repos = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: 0, height: 2))
        progressView.backgroundColor = .blueColor()
        navigationController?.navigationBar.addSubview(progressView)
        
        downloadRepositories("ashfurrow")
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(ok)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - API Stuff

    func downloadRepositories(username: String) {
        GitHubProvider.request(.UserRepositories(username)) { result in
            switch result {
            case let .Success(response):
                do {
                    if let json = try response.mapJSON() as? NSArray {
                        // Presumably, you'd parse the JSON into a model object. This is just a demo, so we'll keep it as-is.
                        self.repos = json
                    } else {
                        self.showAlert("GitHub Fetch", message: "Unable to fetch from GitHub")
                    }
                } catch {
                    self.showAlert("GitHub Fetch", message: "Unable to fetch from GitHub")
                }
                self.tableView.reloadData()
            case let .Failure(error):
                guard let error = error as? CustomStringConvertible else {
                    break
                }
                self.showAlert("GitHub Fetch", message: error.description)
            }
        }
    }

    func downloadZen() {
        GitHubProvider.request(.Zen) { result in
            var message = "Couldn't access API"
            if case let .Success(response) = result {
                let jsonString = try? response.mapString()
                message = jsonString ?? message
            }
    
            self.showAlert("Zen", message: message)
        }
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

    @IBAction func giphyWasPressed(sender: UIBarButtonItem) {
        uploadGiphy()
    }
    
    @IBAction func searchWasPressed(sender: UIBarButtonItem) {
        var usernameTextField: UITextField?

        let promptController = UIAlertController(title: "Username", message: nil, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in
            if let username = usernameTextField?.text {
                self.downloadRepositories(username)
            }
        }
        promptController.addAction(ok)
        promptController.addTextFieldWithConfigurationHandler { textField in
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
        let repo = repos[indexPath.row] as? NSDictionary
        cell.textLabel?.text = repo?["name"] as? String
        return cell
    }
}
