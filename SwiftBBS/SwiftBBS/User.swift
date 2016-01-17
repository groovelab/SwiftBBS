//
//  User.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/17.
//	Copyright GrooveLab
//

import Foundation

class User {
    private static let keyForUserDefaults = "User_sessionToken"
    
    static var sessionToken: String? {
        get {
            let userDefauls = NSUserDefaults.standardUserDefaults()
            return userDefauls.stringForKey(keyForUserDefaults)
        }
        set {
            guard let sessionToken = newValue else {
                return
            }

            let userDefauls = NSUserDefaults.standardUserDefaults()
            userDefauls.setObject(sessionToken, forKey: keyForUserDefaults)
            userDefauls.synchronize()
        }
    }
}