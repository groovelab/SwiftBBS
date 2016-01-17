//
//  SecondViewController.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import UIKit
import PerfectLib

class MypageViewController: UIViewController {
    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/mypage"
    let END_POINT_LOGOUT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/user/logout"

    var user: JSONDictionaryType?
    var isViewDidAppear = false

    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var createdAtLabel: UILabel!
    @IBOutlet weak private var updatedAtLabel: UILabel!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if User.sessionToken == nil {
            performSegueWithIdentifier("toLoginViewController", sender: nil)
        }
        isViewDidAppear = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "toUserEditViewController", let vc = segue.destinationViewController as? UserEditViewController {
            vc.user = user
        }
    }

    private func fetchData() {
        guard let _ = User.sessionToken else {
            //  need login
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT)!)
        req.HTTPMethod = "GET"
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
                self.didFailFetchData()
                print("response is empty")
                return;
            }
            
            do {
                let jsonDecoded = try JSONDecode().decode(stringData)
                if let jsonMap = jsonDecoded as? JSONDictionaryType {
                    if let userDictionary = jsonMap.dictionary["loginUser"] as? JSONDictionaryType {
                        self.user = userDictionary
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        self.didFetchData()
                    })
                }
            } catch let exception {
                self.didFailFetchData()
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
    
    private func didFetchData() {
        guard let user = user else {
            return
        }
        
        if let id = user.dictionary["id"] as? String {
            idLabel.text = id
        }
        if let name = user.dictionary["name"] as? String {
            nameLabel.text = name
        }
        if let createdAt = user.dictionary["createdAt"] as? String {
            createdAtLabel.text = createdAt
        }
        if let updatedAt = user.dictionary["updatedAt"] as? String {
            updatedAtLabel.text = updatedAt
        }
    }
    
    private func didFailFetchData() {
        User.sessionToken = nil
        
        if isViewDidAppear {
            performSegueWithIdentifier("toLoginViewController", sender: nil)
        }
    }
    
    @IBAction private func logoutAction(sender: UIButton) {
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT_LOGOUT)!)
        req.HTTPMethod = "GET"
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
                                self.didLogout()
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
    
    private func didLogout() {
        User.sessionToken = nil
        performSegueWithIdentifier("toLoginViewController", sender: nil)
    }
    
    @IBAction private func editAction(sender: UIButton) {
        performSegueWithIdentifier("toUserEditViewController", sender: nil)
    }
}

