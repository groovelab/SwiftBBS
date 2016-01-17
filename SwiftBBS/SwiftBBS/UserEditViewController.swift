//
//  UserEditViewController.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/18.
//	Copyright GrooveLab
//

import UIKit
import PerfectLib

class UserEditViewController: UIViewController {
    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/edit"
    let END_POINT_DELETE: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/delete"
    
    var user: JSONDictionaryType?
    
    @IBOutlet weak private var nameTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = user {
            nameTextField.text = user.dictionary["name"] as? String ?? ""
        }
    }
    
    @IBAction private func updateAction(sender: UIButton) {
        doUpdate()
    }

    private func doUpdate() {
        guard let name = nameTextField.text else {
            return
        }
        guard let password = passwordTextField.text else {
            return
        }
        if name.isEmpty {
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT)!)
        req.HTTPMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addTokenToCookie()
        
        let postBody = "name=\(name)" + (password.isEmpty ? "" : "&password=\(password)")
        req.HTTPBody = postBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (data:NSData?, res:NSURLResponse?, error:NSError?) -> Void in
            if let error = error {
                print("Request failed with error \(error)")
                return;
            }
            
            guard let data = data, let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
                print("response is empty")
                return;
            }
            
            do {
                let jsonDecoded = try JSONDecode().decode(stringData)
                if let jsonMap = jsonDecoded as? JSONDictionaryType {
                    if let status = jsonMap["status"] as? String {
                        if status == "success" {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.didPost()
                            })
                        } else {
                            print("update failed")
                        }
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
    
    private func didPost() {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction private func deleteAction(sender: UIButton) {
        doDelete()
    }
    
    private func doDelete() {
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT_DELETE)!)
        req.HTTPMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addTokenToCookie()
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (data:NSData?, res:NSURLResponse?, error:NSError?) -> Void in
            if let error = error {
                print("Request failed with error \(error)")
                return;
            }
            
            guard let data = data, let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
                print("response is empty")
                return;
            }
            
            do {
                let jsonDecoded = try JSONDecode().decode(stringData)
                if let jsonMap = jsonDecoded as? JSONDictionaryType {
                    if let status = jsonMap["status"] as? String {
                        if status == "success" {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.didPost()
                            })
                        } else {
                            print("delete failed")
                        }
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
}
