//
//  BbsDetailTableViewCell.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/17.
//	Copyright GrooveLab
//

import UIKit

class BbsDetailTableViewCell: UITableViewCell {
    var item: [String: Any]? {
        didSet {
            guard let item = item else {
                return
            }
            if let comment = item["comment"] as? String {
                commentLabel.text = comment
            }
            if let userName = item["userName"] as? String {
                userNameLabel.text = userName
            }
            if let createdAt = item["createdAt"] as? String {
                createdAtLabel.text = createdAt
            }
        }
    }
    @IBOutlet weak private var commentLabel: UILabel!
    @IBOutlet weak private var userNameLabel: UILabel!
    @IBOutlet weak private var createdAtLabel: UILabel!
    
    @IBOutlet weak private var topMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak private var middleMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak private var bottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak private var leftMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak private var rightMarginConstraint: NSLayoutConstraint!
    
    func fittingSizeForWith(width: CGFloat) -> CGSize {
        let commentLabelSize = commentLabel.sizeThatFits(CGSize(width: width - leftMarginConstraint.constant - rightMarginConstraint.constant, height: CGFloat.max))
        let cellHeight = topMarginConstraint.constant + commentLabelSize.height + middleMarginConstraint.constant + userNameLabel.frame.height + bottomMarginConstraint.constant
        return CGSize(width: width, height: cellHeight)
    }
}
