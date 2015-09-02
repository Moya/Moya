//
//  ReactiveMoyaViewController.swift
//  MoyaExample
//
//  Created by Justin Makaila on 7/14/15.
//  Copyright (c) 2015 Justin Makaila. All rights reserved.
//

import UIKit
import ReactiveMoya
import ReactiveCocoa
import Result

let ReactiveGithubProvider = ReactiveCocoaMoyaProvider<Github>()

class ReactiveMoyaViewController: UITableViewController, UIGestureRecognizerDelegate {
    let repos = MutableProperty<NSArray>(NSArray())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - API
    
    func downloadRepositories(username: String) {
        ReactiveGithubProvider.requestJSONArray(.UserRepositories(username))
            |> start(error: { (error: NSError) in
                self.showErrorAlert("Github Fetch", error: error)
            },
            next: { (result: NSArray) in
                self.repos.put(result)
                self.title = "\(username)'s repos"
            })
    }
    
    func downloadZen() {
        ReactiveGithubProvider.requestString(.Zen)
            |> start(error: { (error: NSError) in
                self.showErrorAlert("Zen", error: error)
            },
            next: { (string: String) in
                self.showAlert("Zen", message: string)
            })
    }
    
    // MARK: - Actions
    // MARK: IBActions
    
    @IBAction func searchPressed(sender: UIBarButtonItem) {
        showInputPrompt("Username", message: "Enter a github username", action: { username in
            self.downloadRepositories(username)
        })
    }
    
    @IBAction func zenPressed(sender: UIBarButtonItem) {
        downloadZen()
    }
    
    // MARK: - Delegates
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.value.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        if let object = repos.value[indexPath.row] as? NSDictionary {
            cell.textLabel?.text = object["name"] as? String
        }
        
        return cell
    }
    
    // MARK: - Setup
    
    private func setup() {
        self.navigationController?.interactivePopGestureRecognizer.delegate = self
        
        // When repos changes and is non-nil, reload the table view
        repos.producer
            |> start(next: { _ in
                self.tableView.reloadData()
            })
        
        // Download all repositories for "justinmakaila"
        downloadRepositories("justinmakaila")
    }
}
