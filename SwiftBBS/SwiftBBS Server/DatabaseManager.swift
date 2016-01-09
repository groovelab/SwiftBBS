//
//  DatabaseManager.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/10.
//	Copyright GrooveLab
//
//

import PerfectLib

class DatabaseManager {
    static var path: String?
    static var db: SQLite {
        if let db = _db {
            return db
        }
        
        do {
            _db = try SQLite(path!)
        } catch(let e) {
            print(e)
        }
        return _db!
    }
    private static var _db: SQLite?
    
    static func close() {
        if _db != nil {
            _db = nil
        }
    }
}
