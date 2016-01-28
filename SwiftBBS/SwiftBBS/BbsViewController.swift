//
//  BbsViewController.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import UIKit
import PerfectLib

class BbsViewController: UIViewController {
    static let ADDED_BBS_NOTIFICATION = "added_bbs"

    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/bbs"
    
    var bbsArray: JSONArrayType?

    private var cellForHeight: BbsTableViewCell!

    @IBOutlet weak private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cellForHeight = tableView.dequeueReusableCellWithIdentifier(BbsTableViewCell.identifierForReuse) as! BbsTableViewCell
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addedBbs:", name: self.dynamicType.ADDED_BBS_NOTIFICATION, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "toBbsDetailViewController", let vc = segue.destinationViewController as? BbsDetailViewController, let indexPath = sender as? NSIndexPath {
            if let bbsArray = bbsArray, let bbs = bbsArray.array[indexPath.row] as? JSONDictionaryType {
                if let bbsId = bbs.dictionary["id"] as? Int {
                    vc.bbsId = bbsId
                }
            } else if let bbsId = sender as? Int {
                vc.bbsId = bbsId
            }
        }
    }

    func addedBbs(notification: NSNotification) {
        guard let userInfo = notification.userInfo, let bbsId = userInfo["bbsId"] as? Int else {
            return
        }
        performSegueWithIdentifier("toBbsDetailViewController", sender: bbsId)
    }
    
    private func fetchData() {
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
                print("response is empty")
                return;
            }

            do {
                let jsonDecoded = try JSONDecoder().decode(stringData)
                if let jsonMap = jsonDecoded as? JSONDictionaryType {
                    if let bbsList = jsonMap.dictionary["bbsList"] as? JSONArrayType {
                        self.bbsArray = bbsList
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.didFetchData()
                        })
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }

    private func didFetchData() {
        tableView.reloadData()
    }
    
    @IBAction private func addAction(sender: UIButton) {
        performSegueWithIdentifier("toBbsAddViewController", sender: nil)
    }
}

extension BbsViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let bbsArray = bbsArray else {
            return 0
        }
        
        return bbsArray.array.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        cellForHeight.prepareForReuse()
        configureCell(cellForHeight, indexPath: indexPath)
        return cellForHeight.fittingSizeForWith(view.frame.width).height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BbsTableViewCell.identifierForReuse, forIndexPath: indexPath) as! BbsTableViewCell
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("toBbsDetailViewController", sender: indexPath)
    }

    private func configureCell(cell: BbsTableViewCell, indexPath: NSIndexPath) {
        if let bbsArray = bbsArray, let bbs = bbsArray.array[indexPath.row] as? JSONDictionaryType {
            cell.item = bbs.dictionary
        }
    }
}
