//
//  UserRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//	Copyright GrooveLab
//

import PerfectLib

enum UserProvider : String {
    case Github = "github"
    case Facebook = "facebook"
}

//  MARK: entity
struct UserEntity {
    var id: Int?
    var name: String
    var password: String?
    var provider: UserProvider?
    var providerUserId: String?
    var providerUserName: String?
    var createdAt: String?
    var updatedAt: String?
    
    init(id: Int?, name: String, password: String?) {
        self.id = id
        self.name = name
        self.password = password
    }
    
    init(id: Int?, provider: UserProvider, providerUserId: String, providerUserName: String) {
        self.id = id
        self.name = provider.rawValue + " : " + providerUserName
        self.password = ""
        self.provider = provider
        self.providerUserId = providerUserId
        self.providerUserName = providerUserName
    }

    init(id: Int?, name: String, password: String?, provider: UserProvider?, providerUserId: String?, providerUserName: String?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.name = name
        self.password = password
        self.provider = provider
        self.providerUserId = providerUserId
        self.providerUserName = providerUserName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id ?? 0,
            "name": name,
            "password": "",//  exclude password
            "provider": provider?.rawValue ?? "",
            "provider_user_id": providerUserId ?? "",
            "provider_user_name": providerUserName ?? "",
            "createdAt": createdAt ?? "",
            "updatedAt": updatedAt ?? "",
        ]
    }
}

//  MARK: - repository
class UserRepository : Repository {
    func insert(entity: UserEntity) throws -> Int {
        let sql = "INSERT INTO user (name, \(entity.password != nil ? "password," : "") "
            + "\(entity.provider != nil ? "provider," : "") \(entity.providerUserId != nil ? "provider_user_id," : "") \(entity.providerUserName != nil ? "provider_user_name," : "") "
            + "created_at, updated_at) VALUES "
            + "(:name, \(entity.password != nil ? ":password," : "") "
            + "\(entity.provider != nil ? ":provider," : "") \(entity.providerUserId != nil ? ":providerUserId," : "") \(entity.providerUserName != nil ? ":providerUserName," : "") datetime('now'), datetime('now'))"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(":name", entity.name)
            if let password = entity.password {
                try stmt.bind(":password", password.sha1)
            }
            if let provider = entity.provider {
                try stmt.bind(":provider", provider.rawValue)
            }
            if let providerUserId = entity.providerUserId {
                try stmt.bind(":providerUserId", providerUserId)
            }
            if let providerUserName = entity.providerUserName {
                try stmt.bind(":providerUserName", providerUserName)
            }
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
        
        let sql = "UPDATE user SET name = :name, \(entity.password != nil ? "password = :password," : "") updated_at = datetime('now') WHERE id = :id"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(":name", entity.name)
            if let password = entity.password {
                try stmt.bind(":password", password.sha1)
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
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, created_at, updated_at FROM user WHERE id = :1"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, id)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
            columns.append(stmt.columnText(3))
            columns.append(stmt.columnText(4))
            columns.append(stmt.columnText(5))
            columns.append(stmt.columnText(6))
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
            provider: (columns[2] as? String) != nil ? UserProvider(rawValue: (columns[2] as? String)!) : nil,
            providerUserId: columns[3] as? String,
            providerUserName: columns[4] as? String,
            createdAt: columns[5] as? String,
            updatedAt: columns[6] as? String
        )
    }
    
    func findByName(name: String, password: String) throws -> UserEntity? {
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, created_at, updated_at FROM user WHERE name = :1 AND password = :2"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, name)
            try stmt.bind(2, password.sha1)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
            columns.append(stmt.columnText(3))
            columns.append(stmt.columnText(4))
            columns.append(stmt.columnText(5))
            columns.append(stmt.columnText(6))
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
            provider: (columns[2] as? String) != nil ? UserProvider(rawValue: (columns[2] as? String)!) : nil,
            providerUserId: columns[3] as? String,
            providerUserName: columns[4] as? String,
            createdAt: columns[5] as? String,
            updatedAt: columns[6] as? String
        )
    }
    
    func findByProviderId(providerId: String, provider: UserProvider) throws -> UserEntity? {
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, created_at, updated_at FROM user WHERE provider = :1 AND provider_user_id = :2"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, provider.rawValue)
            try stmt.bind(2, providerId)
            }) { (stmt:SQLiteStmt, r:Int) -> () in
                columns.append(stmt.columnInt(0))
                columns.append(stmt.columnText(1))
                columns.append(stmt.columnText(2))
                columns.append(stmt.columnText(3))
                columns.append(stmt.columnText(4))
                columns.append(stmt.columnText(5))
                columns.append(stmt.columnText(6))
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
            provider: (columns[2] as? String) != nil ? UserProvider(rawValue: (columns[2] as? String)!) : nil,
            providerUserId: columns[3] as? String,
            providerUserName: columns[4] as? String,
            createdAt: columns[5] as? String,
            updatedAt: columns[6] as? String
        )
    }
}
