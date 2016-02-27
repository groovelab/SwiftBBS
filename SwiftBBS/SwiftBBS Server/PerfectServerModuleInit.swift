//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//  Copyright GrooveLab
//

import PerfectLib
import MySQL

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
        let dbManager = try DatabaseManager()
        try dbManager.query("CREATE TABLE IF NOT EXISTS user (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100), password VARCHAR(100), provider VARCHAR(100), provider_user_id VARCHAR(100), provider_user_name VARCHAR(100), created_at DATETIME, updated_at DATETIME, UNIQUE(name), UNIQUE(provider, provider_user_id))")
        try dbManager.query("CREATE TABLE IF NOT EXISTS bbs (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, title TEXT, comment TEXT, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME)")
        try dbManager.query("CREATE TABLE IF NOT EXISTS bbs_comment (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, bbs_id INT UNSIGNED, comment TEXT, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME, KEY(bbs_id))")
        try dbManager.query("CREATE TABLE IF NOT EXISTS image (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, parent VARCHAR(20), parent_id INT UNSIGNED, path TEXT, ext VARCHAR(10), original_name TEXT, width INT UNSIGNED, height INT UNSIGNED, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME, KEY(parent, parent_id))")
    } catch {
        print(error)
    }
    

    
    // Create our SQLite database.
//    do {
//        let sqlite = try SQLite(Config.sqliteDbPath)    //  TODO:use MySQL
//        try sqlite.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT, password TEXT, provider TEXT, provider_user_id Text, provider_user_name Text, created_at TEXT, updated_at TEXT)")
//        try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS user_name ON user (name)")
//        try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS provider_user ON user (provider, provider_user_id)")
//        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs (id INTEGER PRIMARY KEY, title TEXT, comment TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)")
//        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs_comment (id INTEGER PRIMARY KEY, bbs_id INTEGER, comment TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)")
//        try sqlite.execute("CREATE INDEX IF NOT EXISTS bbs_comment_bbs_id ON bbs_comment (bbs_id)")
//        try sqlite.execute("CREATE TABLE IF NOT EXISTS image (id INTEGER PRIMARY KEY, parent TEXT, parent_id INTEGER, path TEXT, ext TEXT, original_name TEXT, width INTEGER, height INTEGER, user_id INTEGER, created_at TEXT, updated_at TEXT)")
//        try sqlite.execute("CREATE INDEX IF NOT EXISTS image_parent ON image (parent, parent_id)")
//    } catch (let e){
//        print("Failure creating database at " + Config.sqliteDbPath)
//        print(e)
//    }
}

enum DatabaseError : ErrorType {
    case Connect(String)
    case Query(String)
}

class DatabaseManager {
    let db: MySQL
    
    init() throws {
        db = MySQL()
        if db.connect(Config.mysqlHost, user: Config.mysqlUser, password: Config.mysqlPassword, db: Config.mysqlDb) == false {
            throw DatabaseError.Connect(db.errorMessage())
        }
    }
    
    func query(sql: String) throws {
        if db.query(sql) == false {
            throw DatabaseError.Query(db.errorMessage())
        }
    }
}



