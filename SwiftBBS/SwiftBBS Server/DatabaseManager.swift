//
//  DatabaseManager.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/03/05.
//  Copyright GrooveLab
//

import MySQL

enum DatabaseError : ErrorType {
    case Connect(String)
    case Query(String)
    case StoreResults
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
    
    func storeResults() throws -> MySQL.Results {
        guard let results = db.storeResults() else {
            throw DatabaseError.StoreResults
        }
        return results
    }
}
