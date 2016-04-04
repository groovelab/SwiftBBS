//
//  LoginViewController.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import UIKit
import PerfectLib

class LoginViewController: UIViewController {
    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/login"
    let DEVICE_TOKEN_END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/apns_device_token"

    typealias DidDeviceTokenClosure = () -> ()
    
    @IBOutlet weak private var nameTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    
    @IBAction func loginAction(sender: UIButton) {
        doLogin()
    }
    
    private func doLogin() {
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
                let jsonDecoded = try JSONDecoder().decode(stringData)
                if let jsonMap = jsonDecoded as? JSONDictionaryType {
                    if let status = jsonMap["status"] as? String {
                        if status == "success" {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.didLogin(res)
                            })
                        } else {
                            print("login failed")
                        }
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }

    private func didLogin(res: NSURLResponse?) {
        saveSessionKey(res)
        doDeviceToken() {
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    private func saveSessionKey(res: NSURLResponse?) {
        guard let res = res as? NSHTTPURLResponse, let allHeaderFields = res.allHeaderFields as? [String: String], let url = res.URL else {
            return
        }

        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(allHeaderFields, forURL: url)
        for cookie in cookies {
            if cookie.name == Config.SESSION_KEY {
                User.sessionToken = cookie.value
            }
        }
    }
    
    private func doDeviceToken(didClosure: DidDeviceTokenClosure) {
        guard let deviceToken = User.deviceToken where !deviceToken.isEmpty else {
            didClosure()
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: DEVICE_TOKEN_END_POINT)!)
        req.HTTPMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addTokenToCookie()
        
        let postBody = "device_token=\(deviceToken)"
        req.HTTPBody = postBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (data:NSData?, res:NSURLResponse?, error:NSError?) -> Void in
            if let error = error {
                print("Request failed with error \(error)")
                dispatch_async(dispatch_get_main_queue(), {
                    didClosure()
                })
                return
            }
            
            guard let data = data, let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
                print("response is empty")
                dispatch_async(dispatch_get_main_queue(), {
                    didClosure()
                })
                return
            }
            
            do {
                let jsonDecoded = try JSONDecoder().decode(stringData)
                if let jsonMap = jsonDecoded as? JSONDictionaryType {
                    if let status = jsonMap["status"] as? String {
                        if status == "success" {
                            dispatch_async(dispatch_get_main_queue(), {
                                didClosure()
                            })
                        } else {
                            print("device token failed")
                        }
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
    
    @IBAction private func registerAction(sender: UIButton) {
        performSegueWithIdentifier("toUserRegisterViewController", sender: nil)
    }
}
