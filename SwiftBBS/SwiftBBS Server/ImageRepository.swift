//
//  ImageRepository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/21.
//	Copyright GrooveLab
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

    var id: Int?
    var parent: Parent
    var parentId: Int
    var path: String
    var ext: String
    var originalName: String
    var width: Int
    var height: Int
    var userId: Int
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
    func insert(entity: ImageEntity) throws -> Int {
        let sql = "INSERT INTO image (parent, parent_id, path, ext, original_name, width, height, user_id, created_at, updated_at) "
            + "VALUES (:1, :2, :3, :4, :5, :6, :7, :8, datetime('now'), datetime('now'))"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.parent.toString())
            try stmt.bind(2, entity.parentId)
            try stmt.bind(3, entity.path)
            try stmt.bind(4, entity.ext)
            try stmt.bind(5, entity.width)
            try stmt.bind(6, entity.height)
            try stmt.bind(7, entity.originalName)
            try stmt.bind(8, entity.userId)
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Insert(errCode)
        }
        
        return db.changes()
    }
    
    func selectBelongTo(parent parent: ImageEntity.Parent, parentId: Int) throws -> [ImageEntity] {
        let sql = "SELECT id, parent, parent_id, path, ext, original_name, width, height, user_id, created_at, updated_at FROM image "
            + "WHERE parent = :1 AND parent_id = :2 ORDER BY id";
        
        var entities = [ImageEntity]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, parent.toString())
            try stmt.bind(2, parentId)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            entities.append(
                ImageEntity(
                    id: stmt.columnInt(0),
                    parent: ImageEntity.Parent(value: stmt.columnText(1)),
                    parentId: stmt.columnInt(2),
                    path: stmt.columnText(3),
                    ext: stmt.columnText(4),
                    originalName: stmt.columnText(5),
                    width: stmt.columnInt(6),
                    height: stmt.columnInt(7),
                    userId: stmt.columnInt(8),
                    createdAt: stmt.columnText(9),
                    updatedAt: stmt.columnText(10)
                )
            )
        }
        
        return entities
    }
}
