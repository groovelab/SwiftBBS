//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//  Copyright GrooveLab
//

import PerfectLib

//  MARK: - init
public func PerfectServerModuleInit() {
    Routing.Handler.registerGlobally()
    
    //  URL Routing
    Routing.Routes["GET", ["/assets/*/*"]] = { _ in return StaticFileHandler() }
    Routing.Routes["GET", ["/uploads/*"]] = { _ in return StaticFileHandler() }
    
    //  user
    Routing.Routes["GET", ["/user", "/user/{action}"]] = { _ in return UserHandler() }
    Routing.Routes["POST", ["/user/{action}"]] = { _ in return UserHandler() }

    //  bbs
    Routing.Routes["GET", ["/", "/bbs", "/bbs/{action}", "/bbs/{action}/{id}"]] = { _ in return BbsHandler() }
    Routing.Routes["POST", ["/bbs/{action}"]] = { _ in return BbsHandler() }

    //  oauth
    Routing.Routes["GET", ["/oauth/{action}"]] = { _ in return OAuthHandler() }
    
    print("\(Routing.Routes.description)")

    //  Create MySQL Tables
    do {
        //  must create database
        //  mysql> CREATE DATABASE SwiftBBS DEFAULT CHARACTER SET utf8mb4;
        let dbManager = try DatabaseManager()
        try dbManager.query("CREATE TABLE IF NOT EXISTS user (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100), password VARCHAR(100), provider VARCHAR(100), provider_user_id VARCHAR(100), provider_user_name VARCHAR(100), apns_device_token VARCHAR(200), created_at DATETIME, updated_at DATETIME, UNIQUE(name), UNIQUE(provider, provider_user_id))")
        try dbManager.query("CREATE TABLE IF NOT EXISTS bbs (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, title TEXT, comment TEXT, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME)")
        try dbManager.query("CREATE TABLE IF NOT EXISTS bbs_comment (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, bbs_id INT UNSIGNED, comment TEXT, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME, KEY(bbs_id))")
        try dbManager.query("CREATE TABLE IF NOT EXISTS image (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, parent VARCHAR(20), parent_id INT UNSIGNED, path TEXT, ext VARCHAR(10), original_name TEXT, width INT UNSIGNED, height INT UNSIGNED, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME, KEY(parent, parent_id))")
    } catch {
        print(error)
    }
    
    //  APNS setting
    NotificationPusher.addConfigurationIOS(Config.apnsConfigurationName) {
        (net:NetTCPSSL) in
        
        // This code will be called whenever a new connection to the APNS service is required.
        // Configure the SSL related settings.
        
        net.keyFilePassword = ""
        
        guard net.useCertificateChainFile("Cert/entrust_2048_ca.pem") &&
            net.useCertificateFile("Cert/aps_development.pem") &&
            net.usePrivateKeyFile("Cert/key.pem") &&
            net.checkPrivateKey() else {
                
                let code = Int32(net.errorCode())
                print("Error validating private key file: \(net.errorStr(code))")
                return
        }
    }
    
    NotificationPusher.development = true // set to toggle to the APNS sandbox server
}
