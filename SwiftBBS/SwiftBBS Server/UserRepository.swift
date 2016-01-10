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
    var updatedAt: String?
    
    func toDictionary() -> [String: Any] {  //  TODO:declare method in protocol
        return [
            "id": id ?? 0,
            "name": name,
            "password": "",//  exclude password
            "createdAt": createdAt ?? "",
            "updatedAt": updatedAt ?? "",
        ]
    }
}

//  MARK: - repository
class UserRepository : Repository {
    func insert(entity: UserEntity) throws -> Int {
        let sql = "INSERT INTO user (name, password, created_at, updated_at) VALUES (:1, :2, datetime('now'), datetime('now'))"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.name)
            try stmt.bind(2, entity.password)   //  TODO:encrypt
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Insert(errCode)
        }
        
        return db.changes()
    }
    
    func update(entity: UserEntity) throws -> Int {
        guard let id = entity.id else {
            return 0
        }
        
        let sql = "UPDATE user SET name = :name, \(entity.password.isEmpty ? "" : "password = :password,") updated_at = datetime('now') WHERE id = :id"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(":name", entity.name)
            if !entity.password.isEmpty {
                try stmt.bind(":password", entity.password)
            }
            try stmt.bind(":id", id)
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Update(errCode)
        }
        
        return db.changes()
    }
    
    func delete(entity: UserEntity) throws -> Int {
        guard let id = entity.id else {
            return 0
        }
        
        let sql = "DELETE FROM user WHERE id = :1"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, id)
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Delete(errCode)
        }
        
        return db.changes()
    }
    
    func findById(id: Int) throws -> UserEntity? {
        let sql = "SELECT id, name, created_at , updated_at FROM user WHERE id = :1"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, id)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
            columns.append(stmt.columnText(3))
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
            createdAt: columns[2] as? String,
            updatedAt: columns[3] as? String
        )
    }
    
    func findByName(name: String, password: String) throws -> UserEntity? {
        let sql = "SELECT id, name, created_at, updated_at FROM user WHERE name = :1 AND password = :2"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, name)
            try stmt.bind(2, password)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
            columns.append(stmt.columnText(3))
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
            createdAt: columns[2] as? String,
            updatedAt: columns[2] as? String
        )
    }
}
