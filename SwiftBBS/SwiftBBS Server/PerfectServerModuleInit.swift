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
    
    //  user
    Routing.Routes["GET", ["/user", "/user/{action}"]] = { _ in return UserHandler() }
    Routing.Routes["POST", ["/user/{action}"]] = { _ in return UserHandler() }

    //  bbs
    Routing.Routes["GET", ["/", "/bbs", "/bbs/{action}", "/bbs/{action}/{id}"]] = { _ in return BbsHandler() }
    Routing.Routes["POST", ["/bbs/{action}"]] = { _ in return BbsHandler() }

    print("\(Routing.Routes.description)")
    
    // Create our SQLite database.
    do {
        let sqlite = try SQLite(Config.dbPath)    //  TODO:use MySQL
        try sqlite.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT, password TEXT, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS user_name ON user (name)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs (id INTEGER PRIMARY KEY, title TEXT, comment TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs_comment (id INTEGER PRIMARY KEY, bbs_id INTEGER, comment TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT)")
        try sqlite.execute("CREATE INDEX IF NOT EXISTS bbs_comment_bbs_id ON bbs_comment (bbs_id);")
    } catch (let e){
        print("Failure creating database at " + Config.dbPath)
        print(e)
    }
}
