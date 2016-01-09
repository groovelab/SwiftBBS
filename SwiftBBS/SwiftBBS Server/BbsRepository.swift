//
//  BbsRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//	Copyright GrooveLab
//
//

import PerfectLib

//  MARK: entity
struct BbsEntity {
    var id: Int?
    var title: String
    var comment: String
    var userId: Int
    var createdAt: String?
}

struct BbsWithUserEntity {
    var id: Int
    var title: String
    var comment: String
    var userId: Int
    var userName: String
    var createdAt: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "comment" : comment,
            "userId" : userId,
            "userName" : userName,
            "createdAt" : createdAt,
        ]
    }
}

//  MARK: - repository
enum RepositoryError : ErrorType {
    case Select(Int)
    case Insert(Int)
    case Update(Int)
    case Delete(Int)
}

class BbsRepository {
    func insert(var entity: BbsEntity) throws -> BbsEntity {
        let sqlite = try SQLite(DB_PATH)    //  TODO:refactor
        defer { sqlite.close() }
        
        let sql = "INSERT INTO bbs (title, comment, user_id, created_at) VALUES (:1, :2, :3, datetime('now'))"
        try sqlite.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.title)
            try stmt.bind(2, entity.comment)
            try stmt.bind(3, entity.userId)
        }
        
        let errCode = sqlite.errCode()
        if errCode > 0 {
            throw RepositoryError.Insert(errCode)
        }
        
        entity.id = sqlite.lastInsertRowID()
        return entity
    }
    
    func findById(id: Int) throws -> BbsWithUserEntity? {
        let sqlite = try SQLite(DB_PATH)    //  TODO:refactor
        defer { sqlite.close() }
        
        let sql = "SELECT b.id, b.title, b.comment, b.user_id, u.name, b.created_at FROM bbs as b INNER JOIN user AS u ON u.id = b.user_id WHERE b.id = :1"
        var columns = [Any]()
        try sqlite.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, id)
        }) {(stmt:SQLiteStmt, r:Int) -> () in
            columns.append(stmt.columnInt(0))
            columns.append(stmt.columnText(1))
            columns.append(stmt.columnText(2))
            columns.append(stmt.columnInt(3))
            columns.append(stmt.columnText(4))
            columns.append(stmt.columnText(5))
        }
        
        let errCode = sqlite.errCode()
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
            createdAt: columns[5] as! String
        )
    }
    
    func selectByKeyword(keyword: String?) throws -> [BbsWithUserEntity] {
        let sqlite = try SQLite(DB_PATH)    //  TODO:refactor
        defer { sqlite.close() }
        
        let sql = "SELECT b.id, b.title, b.comment, b.user_id, u.name, b.created_at FROM bbs AS b "
            + "INNER JOIN user as u ON u.id = b.user_id "
            + "\(keyword != nil ? "WHERE b.title LIKE :1 OR b.comment LIKE :1" : "") "
            + "ORDER BY b.id"
        
        var entities = [BbsWithUserEntity]()
        try sqlite.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            if let keyword = keyword {
                try stmt.bind(1, "%" + keyword + "%")
            }
        }) {(stmt:SQLiteStmt, r:Int) -> () in
            entities.append(
                BbsWithUserEntity(
                    id: stmt.columnInt(0),
                    title: stmt.columnText(1),
                    comment: stmt.columnText(2),
                    userId: stmt.columnInt(3),
                    userName: stmt.columnText(4),
                    createdAt: stmt.columnText(5)
                )
            )
        }
        
        return entities
    }
}
