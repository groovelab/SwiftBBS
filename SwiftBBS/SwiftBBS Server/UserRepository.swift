//
//  UserRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//  Copyright GrooveLab
//

import PerfectLib
import MySQL

enum UserProvider : String {
    case Github = "github"
    case Facebook = "facebook"
    case Google = "google"
}

//  MARK: entity
struct UserEntity {
    var id: UInt?
    var name: String
    var password: String?
    var provider: UserProvider?
    var providerUserId: String?
    var providerUserName: String?
    var apnsDeviceToken: String?
    var createdAt: String?
    var updatedAt: String?
    
    init(id: UInt?, name: String, password: String?) {
        self.id = id
        self.name = name
        self.password = password
    }
    
    init(id: UInt?, provider: UserProvider, providerUserId: String, providerUserName: String) {
        self.id = id
        self.name = provider.rawValue + " : " + providerUserName
        self.password = ""
        self.provider = provider
        self.providerUserId = providerUserId
        self.providerUserName = providerUserName
    }

    init(id: UInt?, name: String, password: String?, provider: UserProvider?, providerUserId: String?, providerUserName: String?, apnsDeviceToken: String?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.name = name
        self.password = password
        self.provider = provider
        self.providerUserId = providerUserId
        self.providerUserName = providerUserName
        self.apnsDeviceToken = apnsDeviceToken
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
    func insert(entity: UserEntity) throws -> UInt {
        let sql = "INSERT INTO user (name, \(entity.password != nil ? "password," : "") "
            + "\(entity.provider != nil ? "provider," : "") \(entity.providerUserId != nil ? "provider_user_id," : "") \(entity.providerUserName != nil ? "provider_user_name," : "") "
            + "created_at, updated_at) VALUES "
            + "(?, \(entity.password != nil ? "?," : "") "
            + "\(entity.provider != nil ? "?," : "") \(entity.providerUserId != nil ? "?," : "") \(entity.providerUserName != nil ? "?," : "") \(nowSql), \(nowSql))"
        
        var params: Params = [ entity.name ]
        if let password = entity.password {
            params.append(password.sha1)
        }
        if let provider = entity.provider {
            params.append(provider.rawValue)
        }
        if let providerUserId = entity.providerUserId {
            params.append(providerUserId)
        }
        if let providerUserName = entity.providerUserName {
            params.append(providerUserName)
        }

        return try executeInsertSql(sql, params: params)
    }
    
    func update(entity: UserEntity) throws -> UInt {
        guard let id = entity.id else {
            return 0
        }
        
        let sql = "UPDATE user SET name = ?, \(!String.isEmpty(entity.password) ? "password = ?," : "") \(!String.isEmpty(entity.apnsDeviceToken) ? "apns_tevice_token = ?," : "") updated_at = \(nowSql) WHERE id = ?"

        var params: Params = [ entity.name ]
        if let password = entity.password where !String.isEmpty(entity.password) {
            params.append(password.sha1)
        }
        if let apnsDeviceToken = entity.apnsDeviceToken where !String.isEmpty(entity.apnsDeviceToken) {
            params.append(apnsDeviceToken)
        }
        params.append(id)
        
        return try executeUpdateSql(sql, params: params)
    }
    
    func delete(entity: UserEntity) throws -> UInt {
        guard let id = entity.id else {
            return 0
        }
        
        let sql = "DELETE FROM user WHERE id = ?"
        return try executeDeleteSql(sql, params: [ id ])
    }
    
    func findById(id: UInt) throws -> UserEntity? {
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, apns_device_token, created_at, updated_at FROM user WHERE id = ?"
        let rows = try executeSelectSql(sql, params: [ id ])
        guard let row = rows.first else {
            return nil
        }

        return createEntityFromRow(row)
    }
    
    func findByName(name: String, password: String) throws -> UserEntity? {
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, apns_device_token, created_at, updated_at FROM user WHERE name = ? AND password = ?"
        let rows = try executeSelectSql(sql, params: [ name, password.sha1 ])
        guard let row = rows.first else {
            return nil
        }

        return createEntityFromRow(row)
    }
    
    func findByProviderId(providerId: String, provider: UserProvider) throws -> UserEntity? {
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, apns_device_token, created_at, updated_at FROM user WHERE provider = ? AND provider_user_id = ?"
        let rows = try executeSelectSql(sql, params: [ provider.rawValue, providerId ])
        guard let row: Row = rows.first else {
            return nil
        }

        return createEntityFromRow(row)
    }
    
    func selectByIds(ids: [UInt]) throws -> [UserEntity] {
        let sql = "SELECT id, name, provider, provider_user_id, provider_user_name, apns_device_token, created_at, updated_at FROM user WHERE id IN (?)"
        var params = Params()
        params.append(ids.map { String($0) }.joinWithSeparator(","))
        let rows = try executeSelectSql(sql, params: params)
        return rows.map { row in
            return createEntityFromRow(row)
        }
    }
    
    //  row contains 
    //  id, name, provider, provider_user_id, provider_user_name, apns_device_token, created_at, updated_at
    private func createEntityFromRow(row: Row) -> UserEntity {
        return UserEntity(
            id: UInt(row[0] as! UInt32),
            name: row[1] as! String,
            password: "",
            provider: (row[2] as? String) != nil ? UserProvider(rawValue: (row[2] as? String)!) : nil,
            providerUserId: row[3] as? String,
            providerUserName: row[4] as? String,
            apnsDeviceToken: row[5] as? String,
            createdAt: row[6] as? String,
            updatedAt: row[7] as? String
        )
    }
}
