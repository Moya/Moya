//
//  ReactiveMoyaViewController.swift
//  MoyaExample
//
//  Created by Justin Makaila on 7/14/15.
//  Copyright (c) 2015 Justin Makaila. All rights reserved.
//

import UIKit
import RxMoya

let RxGithubProvider = RxMoyaProvider<Github>()

class RxMoyaViewController: UITableViewController, UIGestureRecognizerDelegate {
    var repos = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - API
    
    func downloadRepositories(username: String) {
        // TODO: Handle success and error
        RxGithubProvider.request(.UserRepositories(username))
    }
    
    func downloadZen() {
        // TODO: Handle success and error
        RxGithubProvider.request(.Zen)
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
        return repos.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        if let object = repos[indexPath.row] as? NSDictionary {
            cell.textLabel?.text = object["name"] as? String
        }
        
        return cell
    }
    
    // MARK: - Setup
    
    private func setup() {
        self.navigationController?.interactivePopGestureRecognizer.delegate = self
        
        // Download all repositories for "justinmakaila"
        downloadRepositories("justinmakaila")
    }
}
