//
//  Config.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/02.
//  Copyright GrooveLab
//

import PerfectLib

//  TODO: read from config.plist
class Config {
    static let sessionName = "session"
    static let sessionExpires = 60
    
    static let mysqlHost = "localhost"
    static let mysqlUser = "root"
    static let mysqlPassword = ""
    static let mysqlDb = "SwiftBBS"
    
    static let uploadDirPath = "uploads/"
    static let uploadImageFileSize = 3 * 1024 * 1024
    static let uploadImageFileExtensions = ["jpg","png"]
    static let curlDir = "/usr/bin/"
    
    //  FIXME: enter your id and secret
    static let gitHubClientId = ""
    static let gitHubClientSecret = ""
    static let facebookAppId = ""
    static let facebookAppSecret = ""
    static let googleClientId = ""
    static let googleClientSecret = ""
    static let lineChannelId = ""
    static let lineChannelSecret = ""
    
    static let apnsEnabled = true
    static let apnsConfigurationName = "SwiftBBS"
    static let apnsTopic = "asia.groovelab.SwiftBBS"
    //  FIXME: enter your apns setting
    static let apnsKeyFilePassword = ""
    static let apnsCertificateChainFilePath = "Cert/entrust_2048_ca.pem"
    static let apnsCertificateFilePath = "Cert/aps_development.pem"
    static let apnsPrivateKeyFilePath = "Cert/key.pem"
    static let apnsIsDevelopment = true

#if os(Linux)
    static let imageMagickDir = ""
#else
    static let imageMagickDir = "/usr/local/bin/"
#endif
}
