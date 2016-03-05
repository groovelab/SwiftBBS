//
//  BbsCommentRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//  Copyright GrooveLab
//

import PerfectLib

//  MARK: entity
struct BbsCommentEntity {
    var id: UInt?
    var bbsId: UInt
    var comment: String
    var userId: UInt
    var createdAt: String?
    var updatedAt: String?
}

struct BbsCommentWithUserEntity {
    var id: UInt
    var bbsId: UInt
    var comment: String
    var userId: UInt
    var userName: String
    var createdAt: String
    var updatedAt: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "bbsId": bbsId,
            "comment": comment,
            "userId": userId,
            "userName": userName,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
        ]
    }
}

//  MARK: - repository
class BbsCommentRepository : Repository {
    func insert(entity: BbsCommentEntity) throws -> UInt {
        let sql = "INSERT INTO bbs_comment (bbs_id, comment, user_id, created_at, updated_at) VALUES (?, ?, ?, \(nowSql), \(nowSql))"
        let params: Params = [ entity.bbsId, entity.comment, entity.userId ]
        return try executeInsertSql(sql, params: params)
    }
    
    func selectByBbsId(bbsId: UInt) throws -> [BbsCommentWithUserEntity] {
        let sql = "SELECT b.id, b.bbs_id, b.comment, b.user_id, u.name, b.created_at, b.updated_at FROM bbs_comment AS b "
            + "INNER JOIN user AS u ON u.id = b.user_id WHERE b.bbs_id = ? "
            + "ORDER BY b.id"
        let rows = try executeSelectSql(sql, params: [ bbsId ])
        return rows.map { row in
            return createEntityFromRow(row)
        }
    }
    
    //  row contains b.id, b.bbs_id, b.comment, b.user_id, u.name, b.created_at, b.updated_at
    private func createEntityFromRow(row: Row) -> BbsCommentWithUserEntity {
        return BbsCommentWithUserEntity(
            id: UInt(row[0] as! UInt32),
            bbsId: UInt(row[1] as! UInt32),
            comment: stringFromMySQLText(row[2] as? [UInt8]) ?? "",
            userId: UInt(row[3] as! UInt32),
            userName: row[4] as! String,
            createdAt: row[5] as! String,
            updatedAt: row[6] as! String
        )
    }
}
