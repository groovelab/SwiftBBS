//
//  UserRegisterViewController.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/18.
//	Copyright GrooveLab
//

import UIKit
import PerfectLib

class UserRegisterViewController: UIViewController {
    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/register"
    
    var user: JSONDictionaryType?
    
    @IBOutlet weak private var nameTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    
    @IBAction private func registerAction(sender: UIButton) {
        doRegister()
    }
    
    private func doRegister() {
        guard let name = nameTextField.text else {
            return
        }
        guard let passowrd = passwordTextField.text else {
            return
        }
        if name.isEmpty || passowrd.isEmpty {
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT)!)
        req.HTTPMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addTokenToCookie()
        
        let postBody = "name=\(name)&password=\(passowrd)"
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
                                self.didRegister()
                            })
                        } else {
                            print("register failed")
                        }
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
    
    private func didRegister() {
        navigationController?.popToRootViewControllerAnimated(true)
        navigationController?.viewControllers.first?.dismissViewControllerAnimated(true, completion: nil)
    }
}
