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
    var id: Int?
    var title: String
    var comment: String
    var userId: Int
    var createdAt: String?
    var updatedAt: String?
}

struct BbsWithUserEntity {
    var id: Int
    var title: String
    var comment: String
    var userId: Int
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
    func insert(entity: BbsEntity) throws -> Int {
        let sql = "INSERT INTO bbs (title, comment, user_id, created_at, updated_at) VALUES (:1, :2, :3, datetime('now'), datetime('now'))"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.title)
            try stmt.bind(2, entity.comment)
            try stmt.bind(3, entity.userId)
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Insert(errCode)
        }
        
        return db.changes()
    }
    
    func findById(id: Int) throws -> BbsWithUserEntity? {
        let sql = "SELECT b.id, b.title, b.comment, b.user_id, u.name, b.created_at, b.updated_at FROM bbs as b INNER JOIN user AS u ON u.id = b.user_id WHERE b.id = :1"
        var columns = [Any]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, id)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
            columns.append(stmt.columnInt(3))
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
        
        return BbsWithUserEntity(
            id: columns[0] as! Int,
            title: columns[1] as! String,
            comment: columns[2] as! String,
            userId: columns[3] as! Int,
            userName: columns[4] as! String,
            createdAt: columns[5] as! String,
            updatedAt: columns[6] as! String
        )
    }
    
    func selectByKeyword(keyword: String?, selectOption: SelectOption?) throws -> [BbsWithUserEntity] {
        let sql = "SELECT b.id, b.title, b.comment, b.user_id, u.name, b.created_at, b.updated_at FROM bbs AS b "
            + "INNER JOIN user as u ON u.id = b.user_id "
            + "\(keyword != nil ? "WHERE b.title LIKE :1 OR b.comment LIKE :keyword" : "") "
            + "ORDER BY b.id "
            + "\(selectOption != nil ? selectOption!.limitOffsetSql() : "")"

        var entities = [BbsWithUserEntity]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            if let keyword = keyword {
                try stmt.bind(":keyword", "%" + keyword + "%")
            }
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            entities.append(
                BbsWithUserEntity(
                    id: stmt.columnInt(0),
                    title: stmt.columnText(1),
                    comment: stmt.columnText(2),
                    userId: stmt.columnInt(3),
                    userName: stmt.columnText(4),
                    createdAt: stmt.columnText(5),
                    updatedAt: stmt.columnText(6)
                )
            )
        }
        
        return entities
    }
    
    func countByKeyword(keyword: String?) throws -> Int {
        let sql = "SELECT COUNT(*) FROM bbs AS b "
            + "INNER JOIN user as u ON u.id = b.user_id "
            + "\(keyword != nil ? "WHERE b.title LIKE :1 OR b.comment LIKE :keyword" : "") "
        
        var count = 0
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            if let keyword = keyword {
                try stmt.bind(":keyword", "%" + keyword + "%")
            }
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            count = stmt.columnInt(0)
        }
        
        return count
    }
}
