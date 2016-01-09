//
//  BbsCommentRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//	Copyright GrooveLab
//
//

import PerfectLib

//  MARK: entity
struct BbsCommentEntity {
    var id: Int?
    var bbsId: Int
    var comment: String
    var userId: Int
    var createdAt: String?
}

struct BbsCommentWithUserEntity {
    var id: Int
    var bbsId: Int
    var comment: String
    var userId: Int
    var userName: String
    var createdAt: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "bbsId": bbsId,
            "comment" : comment,
            "userId" : userId,
            "userName" : userName,
            "createdAt" : createdAt,
        ]
    }
}

//  MARK: - repository
class BbsCommentRepository {
    func insert(var entity: BbsCommentEntity) throws -> BbsCommentEntity {
        let sqlite = try SQLite(DB_PATH)    //  TODO:refactor
        defer { sqlite.close() }
        
        let sql = "INSERT INTO bbs_comment (bbs_id, comment, user_id, created_at) VALUES (:1, :2, :3, datetime('now'))"
        try sqlite.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.bbsId)
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
    
    func selectByBbsId(bbsId: Int) throws -> [BbsCommentWithUserEntity] {
        let sqlite = try SQLite(DB_PATH)    //  TODO:refactor
        defer { sqlite.close() }
        
        let sql = "SELECT b.id, b.bbs_id, b.comment, b.user_id, u.name, b.created_at FROM bbs_comment AS b "
            + "INNER JOIN user AS u ON u.id = b.user_id WHERE b.bbs_id = :1 "
            + "ORDER BY b.id"
        var entities = [BbsCommentWithUserEntity]()
        try sqlite.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, bbsId)
        }) {(stmt:SQLiteStmt, r:Int) -> () in
            entities.append(
                BbsCommentWithUserEntity(
                    id: stmt.columnInt(0),
                    bbsId: stmt.columnInt(1),
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
