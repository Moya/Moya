//
//  UIViewControllerExtensions.swift
//  MoyaExample
//
//  Created by Justin Makaila on 7/14/15.
//  Copyright (c) 2015 Justin Makaila. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

    func showErrorAlert(title: String, error: NSError, action: (Void -> Void)? = nil) {
        showAlert(title, message: error.description, action: action)
    }

    func showAlert(title: String, message: String, action: (Void -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: { _ in
            action?()
        })
        
        alertController.addAction(okAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showInputPrompt(title: String, message: String, action: (String -> Void)? = nil) {
        var inputTextField: UITextField?
        
        let promptController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: { _ in
            if let input = inputTextField?.text {
                action?(input)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        promptController.addAction(okAction)
        promptController.addAction(cancelAction)
        promptController.addTextFieldWithConfigurationHandler { textField in
            inputTextField = textField
        }
        
        presentViewController(promptController, animated: true, completion: nil)
    }

}