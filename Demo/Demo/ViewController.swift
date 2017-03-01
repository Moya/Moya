import UIKit
import Moya

class ViewController: UITableViewController {
    var progressView = UIView()
    var repos = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: 0, height: 2))
        progressView.backgroundColor = .blue
        navigationController?.navigationBar.addSubview(progressView)
        
        downloadRepositories("ashfurrow")
    }

    fileprivate func showAlert(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(ok)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - API Stuff

    func downloadRepositories(_ username: String) {
        _ = GitHubProvider.request(.userRepositories(username)) { result in
            switch result {
            case let .success(response):
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
            case let .failure(error):
                guard let error = error as? CustomStringConvertible else {
                    break
                }
                self.showAlert("GitHub Fetch", message: error.description)
            }
        }
    }

    func downloadZen() {
        _ = GitHubProvider.request(.zen) { result in
            var message = "Couldn't access API"
            if case let .success(response) = result {
                let jsonString = try? response.mapString()
                message = jsonString ?? message
            }
    
            self.showAlert("Zen", message: message)
        }
    }
    
    func uploadGiphy() {
        let data = animatedBirdData()
        _ = GiphyProvider.request(.upload(gif: data),
                                  queue: DispatchQueue.main,
                                  progress: progressClosure,
                                  completion: progressCompletionClosure)
    }
    
    func downloadMoyaLogo() {
        _ = GitHubUserContentProvider.request(.downloadMoyaWebContent("logo_github.png"),
                                              queue: DispatchQueue.main,
                                              progress: progressClosure,
                                              completion: progressCompletionClosure)
    }
    
    // MARK: - Progress Helpers
    
    lazy var progressClosure: ProgressBlock = { response in
        UIView.animate(withDuration: 0.3) {
            self.progressView.frame.size.width = self.view.frame.size.width * CGFloat(response.progress)
        }
    }
    
    lazy var progressCompletionClosure: Completion = { result in
        let color: UIColor
        switch result {
        case .success:
            color = .green
        case .failure:
            color = .red
        }
        
        UIView.animate(withDuration: 0.3) {
            self.progressView.backgroundColor = color
            self.progressView.frame.size.width = self.view.frame.size.width
        }
        
        UIView.animate(withDuration: 0.3, delay: 1, options: [],
            animations: {
                self.progressView.alpha = 0
            },
            completion: { _ in
                self.progressView.backgroundColor = .blue
                self.progressView.frame.size.width = 0
                self.progressView.alpha = 1
            }
        )
        
    }

    // MARK: - User Interaction

    @IBAction func giphyWasPressed(_ sender: UIBarButtonItem) {
        uploadGiphy()
    }
    
    @IBAction func searchWasPressed(_ sender: UIBarButtonItem) {
        var usernameTextField: UITextField?

        let promptController = UIAlertController(title: "Username", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { action in
            if let username = usernameTextField?.text {
                self.downloadRepositories(username)
            }
        }
        promptController.addAction(ok)
        promptController.addTextField { textField in
            usernameTextField = textField
        }
        present(promptController, animated: true, completion: nil)
    }

    @IBAction func zenWasPressed(_ sender: UIBarButtonItem) {
        downloadZen()
    }

    @IBAction func downloadWasPressed(_ sender: UIBarButtonItem) {
        downloadMoyaLogo()
    }
    
    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        let repo = repos[(indexPath as NSIndexPath).row] as? NSDictionary
        cell.textLabel?.text = repo?["name"] as? String
        return cell
    }
}
