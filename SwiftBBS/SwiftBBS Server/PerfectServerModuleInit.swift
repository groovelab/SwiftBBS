//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//	Copyright GrooveLab
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

    //  auth
    Routing.Routes["GET", ["/auth", "/auth/{action}"]] = { _ in return AuthHandler() }
    
    print("\(Routing.Routes.description)")
    
    // Create our SQLite database.
    do {
        let sqlite = try SQLite(Config.dbPath)    //  TODO:use MySQL
        try sqlite.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT, password TEXT, provider TEXT, provider_user_id Text, provider_user_name Text, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS user_name ON user (name)")
        try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS provider_user ON user (provider, provider_user_id)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs (id INTEGER PRIMARY KEY, title TEXT, comment TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs_comment (id INTEGER PRIMARY KEY, bbs_id INTEGER, comment TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE INDEX IF NOT EXISTS bbs_comment_bbs_id ON bbs_comment (bbs_id);")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS image (id INTEGER PRIMARY KEY, parent TEXT, parent_id INTEGER, path TEXT, ext TEXT, original_name TEXT, width INTEGER, height INTEGER, user_id INTEGER, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE INDEX IF NOT EXISTS image_parent ON image (parent, parent_id);")
    } catch (let e){
        print("Failure creating database at " + Config.dbPath)
        print(e)
    }
}
