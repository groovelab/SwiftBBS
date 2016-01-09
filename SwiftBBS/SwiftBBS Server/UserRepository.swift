//
//  UserRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//	Copyright GrooveLab
//
//

import PerfectLib

//  MARK: entity
struct UserEntity {
    var id: Int?
    var name: String
    var password: String
    var createdAt: String?
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id ?? 0,
            "name": name,
            "password" : "",//  exclude password
            "createdAt" : createdAt ?? "",
        ]
    }
}

//  MARK: - repository
class UserRepository : Repository {
    func insert(var entity: UserEntity) throws -> UserEntity {
        let sql = "INSERT INTO user (name, password, created_at) VALUES (:1, :2, datetime('now'))"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.name)
            try stmt.bind(2, entity.password)   //  TODO:encrypt
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Insert(errCode)
        }
        
        entity.id = db.lastInsertRowID()
        return entity
    }
    
    func findById(id: Int) throws -> UserEntity? {
        let sql = "SELECT id, name, created_at FROM user WHERE id = :1"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, id)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Select(errCode)
        }
        
        guard columns.count > 0 else {
            return nil
        }
        
        return UserEntity(
            id: columns[0] as? Int,
            name: columns[1] as! String,
            password: "",
            createdAt: columns[2] as? String
        )
    }
    
    func findByName(name: String, password: String) throws -> UserEntity? {
        let sql = "SELECT id, name, created_at FROM user WHERE name = :1 AND password = :2"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, name)
            try stmt.bind(2, password)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
        }

        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Select(errCode)
        }
        
        guard columns.count > 0 else {
            return nil
        }
        
        return UserEntity(
            id: columns[0] as? Int,
            name: columns[1] as! String,
            password: "",
            createdAt: columns[2] as? String
        )
    }
}
