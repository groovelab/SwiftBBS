//
//  Extension.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/17.
//	Copyright GrooveLab
//

import UIKit

extension NSObject {
    static var className: String {
        return NSStringFromClass(self).componentsSeparatedByString(".").last!
    }
}

extension UITableViewCell {
    static var identifierForReuse: String {
        return className
    }
}

extension NSMutableURLRequest {
    func addTokenToCookie() {
        guard let url = URL, let sessionToken = User.sessionToken else {
            return
        }

        var cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(url)
        if cookies == nil {
            return
        }
        
        let properties = [
            NSHTTPCookieDomain: Config.END_POINT_HOST,
            NSHTTPCookiePath: "/",
            NSHTTPCookieName: Config.SESSION_KEY,
            NSHTTPCookieValue: sessionToken
        ]
        if let cookieForSession = NSHTTPCookie(properties: properties) {
            cookies?.append(cookieForSession)
            allHTTPHeaderFields = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies!)
        }
    }
}
