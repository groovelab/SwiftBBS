//
//  RoundedCornerView.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/18.
//	Copyright GrooveLab
//

import UIKit

@IBDesignable class RoundedCornerView : UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let borderColor = layer.borderColor else {
                return UIColor.clearColor()
            }
            return UIColor(CGColor: borderColor)
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
}
