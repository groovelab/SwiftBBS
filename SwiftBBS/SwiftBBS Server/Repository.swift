//
//  Repository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//	Copyright GrooveLab
//

import PerfectLib

enum RepositoryError : ErrorType {
    case Select(Int)
    case Insert(Int)
    case Update(Int)
    case Delete(Int)
}

class Repository {
    let db: SQLite!
    
    init(db: SQLite) {
        self.db = db
    }
    
    func lastInsertId() -> Int {
        return db.lastInsertRowID()
    }
}