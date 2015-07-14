import UIKit
import Moya

let GitHubProvider = MoyaProvider<Github>()

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
                let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                if let json = json as? NSArray {
                    // Presumably, you'd parse the JSON into a model object. This is just a demo, so we'll keep it as-is.
                    self.repos = json
                } else {
                    success = false
                }
                
                self.tableView.reloadData()
            } else {
                success = false
            }
            
            if !success {
                self.showErrorAlert("Github Fetch", error: error!)
            }
        })
    }
    
    func downloadZen() {
        GitHubProvider.request(.Zen, completion: { (data, status, response, error) -> () in
            var message = "Couldn't access API"
            if let data = data {
                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String ?? message
            }
            
            self.showAlert("Zen", message: message)
        })
    }
    
    // MARK: - User Interaction
    
    @IBAction func searchWasPressed(sender: UIBarButtonItem) {
        self.showInputPrompt("Username", message: "Enter a github username", action: { username in
            self.downloadRepositories(username)
        })
    }
    
    @IBAction func zenWasPressed(sender: UIBarButtonItem) {
        downloadZen()
    }
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        let object = repos[indexPath.row] as! NSDictionary
        (cell.textLabel as UILabel!).text = object["name"] as? String
        return cell
    }
}
