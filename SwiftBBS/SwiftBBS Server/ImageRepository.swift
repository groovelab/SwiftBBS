//
//  ImageRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/21.
//  Copyright GrooveLab
//

import PerfectLib

//  MARK: entity
struct ImageEntity {
    enum Parent {
        case Bbs
        case BbsComment
        case User
        
        func toString() -> String {
            switch self {
            case .Bbs:
                return "bbs"
            case .BbsComment:
                return "bbs_comment"
            case .User:
                return "user"
            }
        }
        
        init(value: String) {
            switch value {
            case "bbs":
                self = .Bbs
            case "bbs_comment":
                self = .BbsComment
            case "user":
                self = .User
            default:
                self = .User
            }
        }
    }

    var id: UInt?
    var parent: Parent
    var parentId: UInt
    var path: String
    var ext: String
    var originalName: String
    var width: UInt
    var height: UInt
    var userId: UInt
    var createdAt: String?
    var updatedAt: String?
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "parent": parent.toString(),
            "parentId": parentId,
            "path": path,
            "ext": ext,
            "originalName": originalName,
            "width": userId,
            "height": userId,
            "userId": userId,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
        ]
    }
}

//  MARK: - repository
class ImageRepository : Repository {
    func insert(entity: ImageEntity) throws -> UInt {
        let sql = "INSERT INTO image (parent, parent_id, path, ext, original_name, width, height, user_id, created_at, updated_at) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, \(nowSql), \(nowSql))"
        let params: Params = [
            entity.parent.toString(),
            entity.parentId,
            entity.path,
            entity.ext,
            entity.originalName,
            entity.width,
            entity.height,
            entity.userId
        ]
        return try executeInsertSql(sql, params: params)
    }
    
    func selectBelongTo(parent parent: ImageEntity.Parent, parentId: UInt) throws -> [ImageEntity] {
        let sql = "SELECT id, parent, parent_id, path, ext, original_name, width, height, user_id, created_at, updated_at FROM image "
            + "WHERE parent = ? AND parent_id = ? ORDER BY id";
        let rows = try executeSelectSql(sql, params: [ parent.toString(), parentId ])
        return rows.map { row in
            return createEntityFromRow(row)
        }
    }
    
    //  row contains id, parent, parent_id, path, ext, original_name, width, height, user_id, created_at, updated_at
    private func createEntityFromRow(row: Row) -> ImageEntity {
        return ImageEntity(
            id: UInt(row[0] as! UInt64),
            parent: ImageEntity.Parent(value: row[1] as! String),
            parentId: UInt(row[2] as! UInt64),
            path: stringFromMySQLText(row[3] as? [UInt8]) ?? "",
            ext: row[4] as! String,
            originalName: stringFromMySQLText(row[5] as? [UInt8]) ?? "",
            width: UInt(row[6] as! UInt64),
            height: UInt(row[7] as! UInt64),
            userId: UInt(row[8] as! UInt64),
            createdAt: row[9] as? String,
            updatedAt: row[10] as? String
        )
    }
}
