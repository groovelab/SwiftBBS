//
//  User.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/17.
//	Copyright GrooveLab
//

import Foundation

class User {
    private static let sessionTokenKeyForUserDefaults = "User_sessionToken"
    private static let deviceTokenKeyForUserDefaults = "User_deviceToken"
    
    static var sessionToken: String? {
        get {
            let userDefauls = NSUserDefaults.standardUserDefaults()
            return userDefauls.stringForKey(sessionTokenKeyForUserDefaults)
        }
        set {
            guard let sessionToken = newValue else {
                return
            }

            let userDefauls = NSUserDefaults.standardUserDefaults()
            userDefauls.setObject(sessionToken, forKey: sessionTokenKeyForUserDefaults)
            userDefauls.synchronize()
        }
    }
    
    static var deviceToken: String? {
        get {
            let userDefauls = NSUserDefaults.standardUserDefaults()
            return userDefauls.stringForKey(deviceTokenKeyForUserDefaults)
        }
        set {
            guard let deviceToken = newValue else {
                return
            }
            
            let userDefauls = NSUserDefaults.standardUserDefaults()
            userDefauls.setObject(deviceToken, forKey: deviceTokenKeyForUserDefaults)
            userDefauls.synchronize()
        }
    }
}