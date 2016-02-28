//
//  BbsRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//  Copyright GrooveLab
//

import PerfectLib

//  MARK: entity
struct BbsEntity {
    var id: UInt?
    var title: String
    var comment: String
    var userId: UInt
    var createdAt: String?
    var updatedAt: String?
}

struct BbsWithUserEntity {
    var id: UInt
    var title: String
    var comment: String
    var userId: UInt
    var userName: String
    var createdAt: String
    var updatedAt: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "comment": comment,
            "userId": userId,
            "userName": userName,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
        ]
    }
}

//  MARK: - repository
class BbsRepository : Repository {
    func insert(entity: BbsEntity) throws -> UInt {
        let sql = "INSERT INTO bbs (title, comment, user_id, created_at, updated_at) VALUES (?, ?, ?, \(nowSql), \(nowSql))"
        let params: Params = [ entity.title, entity.comment, entity.userId ]
        return try executeInsertSql(sql, params: params)
    }
    
    func findById(id: UInt) throws -> BbsWithUserEntity? {
        let sql = "SELECT b.id, b.title, b.comment, b.user_id, u.name, b.created_at, b.updated_at FROM bbs as b INNER JOIN user AS u ON u.id = b.user_id WHERE b.id = ?"
        let rows = try executeSelectSql(sql, params: [ id ])
        guard let row = rows.first else {
            return nil
        }
        
        return createEntityFromRow(row)
    }
    
    func selectByKeyword(keyword: String?, selectOption: SelectOption?) throws -> [BbsWithUserEntity] {
        let sql = "SELECT b.id, b.title, b.comment, b.user_id, u.name, b.created_at, b.updated_at FROM bbs AS b "
            + "INNER JOIN user as u ON u.id = b.user_id "
            + "\(keyword != nil ? "WHERE b.title LIKE ? OR b.comment LIKE ?" : "") "
            + "ORDER BY b.id "
            + "\(selectOption != nil ? selectOption!.limitOffsetSql() : "")"
        
        var params = Params()
        if let keyword = keyword {
            params.append("%" + keyword + "%")
        }
        let rows = try executeSelectSql(sql, params: params)
        return rows.map { row in
            return createEntityFromRow(row)
        }
    }
    
    func countByKeyword(keyword: String?) throws -> Int {
        let sql = "SELECT COUNT(*) FROM bbs AS b "
            + "INNER JOIN user as u ON u.id = b.user_id "
            + "\(keyword != nil ? "WHERE b.title LIKE ? OR b.comment LIKE ?" : "") "
        
        var params = Params()
        if let keyword = keyword {
            params.append("%" + keyword + "%")
        }
        
        let rows = try executeSelectSql(sql, params: params)
        guard let row: Row = rows.first, let count = row.first else {
            return 0
        }
        return intFromMySQLCount(count)
    }
    
    //  row contains b.id, b.title, b.comment, b.user_id, u.name, b.created_at, b.updated_at
    private func createEntityFromRow(row: Row) -> BbsWithUserEntity {
        return BbsWithUserEntity(
            id: UInt(row[0] as! UInt64),
            title: stringFromMySQLText(row[1] as? [UInt8]) ?? "",
            comment: stringFromMySQLText(row[2] as? [UInt8]) ?? "",
            userId: UInt(row[3] as! UInt64),
            userName: row[4] as! String,
            createdAt: row[5] as! String,
            updatedAt: row[6] as! String
        )
    }
}
