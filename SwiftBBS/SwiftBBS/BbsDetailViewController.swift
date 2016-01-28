//
//  BbsDetailViewController.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import UIKit
import PerfectLib

class BbsDetailViewController: UIViewController {
    let END_POINT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/bbs/detail/"
    let END_POINT_COMMENT: String = "http://\(Config.END_POINT_HOST):\(Config.END_POINT_PORT)/bbs/addcomment/"

    var bbsId: Int?
    var bbs: JSONDictionaryType?
    var commentArray: JSONArrayType?
    var doScrollBottom = false

    private var cellForHeight: BbsDetailTableViewCell!
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var commentLabel: UILabel!
    @IBOutlet weak private var userNameLabel: UILabel!
    @IBOutlet weak private var createdAtLabel: UILabel!
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var commentTextView: UITextView!
    
    @IBOutlet weak private var bottomMarginConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
        toolBar.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil),
            UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "closeKeyboard:")
        ]
        commentTextView.inputAccessoryView = toolBar
        commentTextView.text = nil
        
        cellForHeight = tableView.dequeueReusableCellWithIdentifier(BbsDetailTableViewCell.identifierForReuse) as! BbsDetailTableViewCell
        fetchData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let keyBoardRectValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval else {
            return
        }
        
        let keyboardRect = keyBoardRectValue.CGRectValue()
        bottomMarginConstraint.constant = keyboardRect.height - (navigationController?.tabBarController?.tabBar.frame.height)!
        UIView.animateWithDuration(duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval else {
                return
        }
        
        bottomMarginConstraint.constant = 0.0
        UIView.animateWithDuration(duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func closeKeyboard(sender: UIBarButtonItem) {
        commentTextView.resignFirstResponder()
    }
    
    private func fetchData() {
        guard let bbsId = bbsId else {
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT + "\(bbsId)")!)
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
                    if let bbsDictionary = jsonMap.dictionary["bbs"] as? JSONDictionaryType {
                        self.bbs = bbsDictionary
                    }
                    if let comments = jsonMap.dictionary["comments"] as? JSONArrayType {
                        self.commentArray = comments
                        
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
        if let bbs = bbs {
            if let title = bbs.dictionary["title"] as? String {
                titleLabel.text = title
            }
            if let comment = bbs.dictionary["comment"] as? String {
                commentLabel.text = comment
            }
            if let userName = bbs.dictionary["userName"] as? String {
                userNameLabel.text = userName
            }
            if let createdAt = bbs.dictionary["createdAt"] as? String {
                createdAtLabel.text = createdAt
            }
        }
    
        tableView.reloadData()
        if doScrollBottom {
            doScrollBottom = false
            if let commentArray = commentArray where commentArray.array.count > 0 {
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: commentArray.array.count - 1, inSection: 0), atScrollPosition: .Bottom, animated: true)
            }
        }
    }
    
    @IBAction private func commentAction(sender: UIButton) {
        doComment()
    }
    
    private func doComment() {
        guard let bbsId = bbsId, let comment = commentTextView.text else {
            return
        }
        if comment.isEmpty {
            return
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: END_POINT_COMMENT)!)
        req.HTTPMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addTokenToCookie()
        
        let postBody = "bbs_id=\(bbsId)&comment=\(comment)"
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
                    if let _ = jsonMap["commentId"] as? Int {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.didComment()
                        })
                    }
                }
            } catch let exception {
                print("JSON decoding failed with exception \(exception)")
            }
        })
        task.resume()
    }
    
    private func didComment() {
        commentTextView.text = nil
        commentTextView.resignFirstResponder()
        doScrollBottom = true
        fetchData()
    }
}

extension BbsDetailViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let commentArray = commentArray else {
            return 0
        }
        
        return commentArray.array.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        cellForHeight.prepareForReuse()
        configureCell(cellForHeight, indexPath: indexPath)
        return cellForHeight.fittingSizeForWith(view.frame.width).height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BbsDetailTableViewCell.identifierForReuse, forIndexPath: indexPath) as! BbsDetailTableViewCell
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func configureCell(cell: BbsDetailTableViewCell, indexPath: NSIndexPath) {
        if let commentArray = commentArray, let comment = commentArray.array[indexPath.row] as? JSONDictionaryType {
            cell.item = comment.dictionary
        }
    }
}
