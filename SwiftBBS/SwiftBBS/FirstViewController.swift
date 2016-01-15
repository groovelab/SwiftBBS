//
//  FirstViewController.swift
//  SwiftBBS
//
//  Created by 難波健雄 on 2016/01/16.
//
//

import UIKit
import PerfectLib

//let END_POINT_HOST = "localhost"
//let END_POINT_PORT = 8181
let END_POINT_HOST = "sakura.groovelab.asia"
let END_POINT_PORT = 80

let END_POINT = "http://\(END_POINT_HOST):\(END_POINT_PORT)/bbs"

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT)!)
        req.HTTPMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
//        req.HTTPBody = postBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (d:NSData?, res:NSURLResponse?, e:NSError?) -> Void in
            if let _ = e {
                print("Request failed with error \(e!)")
            } else {
                
                let strData =  String(data: d!, encoding: NSUTF8StringEncoding)
                print("Request succeeded with data \(strData)")
                do {
                    if let strOk = strData {
                        let jsonDecoded = try JSONDecode().decode(strOk)
                        if let jsonMap = jsonDecoded as? JSONDictionaryType {
                            if let bbsList = jsonMap.dictionary["bbsList"] as? JSONArrayType {
                                // just one result in this app
                                if let result = bbsList.array.first as? JSONDictionaryType {
                                    if let title = result.dictionary["title"] as? String,
                                        let userName = result.dictionary["userName"] as? String,
                                        let userId = result.dictionary["userId"] as? Int,
                                        let createdAt = result.dictionary["createdAt"] as? String,
                                        let updatedAt = result.dictionary["updatedAt"] as? String,
                                        let comment = result.dictionary["comment"] as? String {
                                            
                                            print(title, userName, userId, createdAt, updatedAt, comment)
                                            
                                            
                                            
                                            
//                                            dispatch_async(dispatch_get_main_queue()) {
//                                                self.performSegueWithIdentifier("showMap", sender: self)
//                                            }
                                    }
                                }
                            }
                        }
                    }
                } catch let ex {
                    print("JSON decoding failed with exception \(ex)")
                }
            }
        })
        
        task.resume()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

