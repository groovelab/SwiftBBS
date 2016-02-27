//
//  Config.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/02.
//  Copyright GrooveLab
//

import PerfectLib

class Config {
    static let sessionName = "session"
    static let sessionExpires = 60
    
    static let sqliteDb = "SwiftBBS"
    static let sqliteDbPath = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + sqliteDb
    
    static let mysqlHost = "localhost"
    static let mysqlUser = "root"
    static let mysqlPassword = ""
    static let mysqlDb = "SwiftBBS"
    
    static let uploadDirPath = "uploads/"
    static let uploadImageFileSize = 3 * 1024 * 1024
    static let uploadImageFileExtensions = ["jpg","png"]
    static let curlDir = "/usr/bin/"

    //  FIXME: enter your github developer application credential
    static let gitHubClientId = ""
    static let gitHubClientSecret = ""
    static let facebookAppId = ""
    static let facebookAppSecret = ""
    static let googleClientId = ""
    static let googleClientSecret = ""

#if os(Linux)
    static let imageMagickDir = ""
#else
    static let imageMagickDir = "/usr/local/bin/"
#endif
}
