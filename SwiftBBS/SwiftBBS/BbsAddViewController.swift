//
//  BbsAddViewController.swift
//  SwiftBBS
//
//  Created by 難波健雄 on 2016/01/18.
//
//

import UIKit
import PerfectLib

class BbsAddViewController: UIViewController {
    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/bbs/add"
    
    @IBOutlet weak private var titleTextField: UITextField!
    @IBOutlet weak private var commentTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextView.text = nil
    }
    
    @IBAction func addAction(sender: UIButton) {
        doAdd()
    }
    
    private func doAdd() {
        guard let title = titleTextField.text else {
            return
        }
        guard let comment = commentTextView.text else {
            return
        }
        if title.isEmpty || comment.isEmpty {
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT)!)
        req.HTTPMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addTokenToCookie()
        
        let postBody = "title=\(title)&comment=\(comment)"
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
                    if let bbsId = jsonMap["bbsId"] as? Int {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.didAdd(bbsId)
                        })
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
    
    private func didAdd(bbsId: Int) {
        dismissViewControllerAnimated(true) {
            NSNotificationCenter.defaultCenter().postNotificationName(BbsViewController.ADDED_BBS_NOTIFICATION, object: self, userInfo: ["bbsId": bbsId])
        }
    }

    @IBAction private func closeAction(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
