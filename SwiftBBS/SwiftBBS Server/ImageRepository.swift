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
    var id: Int?
    var parent: String
    var parentId: Int
    var path: String
    var ext: String
    var originalName: String
    var userId: Int
    var createdAt: String?
    var updatedAt: String?
    
    //  TODO: width, height

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "parent": parent,
            "parentId": parentId,
            "path": path,
            "ext": ext,
            "originalName": originalName,
            "userId": userId,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
        ]
    }
    
    static func fileName(fromPath path: String) -> String? {
        return path.componentsSeparatedByString("/").last ?? ""
    }
    
    static func fileExtension(fileName: String) -> String? {
        return fileName.lowercaseString.componentsSeparatedByString(".").last
    }
}

//  MARK: - repository
class ImageRepository : Repository {
    func insert(entity: ImageEntity) throws -> Int {
        let sql = "INSERT INTO image (parent, parent_id, path, ext, original_name, user_id, created_at, updated_at) VALUES (:1, :2, :3, :4, :5, :6, datetime('now'), datetime('now'))"
        try db.execute(sql) { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, entity.parent)
            try stmt.bind(2, entity.parentId)
            try stmt.bind(3, entity.path)
            try stmt.bind(4, entity.ext)
            try stmt.bind(5, entity.originalName)
            try stmt.bind(6, entity.userId)
        }
        
        let errCode = db.errCode()
        if errCode > 0 {
            throw RepositoryError.Insert(errCode)
        }
        
        return db.changes()
    }
    
    func selectBelongTo(parent parent: String, parentId: Int) throws -> [ImageEntity] {
        let sql = "SELECT id, parent, parent_id, path, ext, original_name, user_id, created_at, updated_at FROM image WHERE parent = :1 AND parent_id = :2 ORDER BY id";
        
        var entities = [ImageEntity]()
        try db.forEachRow(sql, doBindings: { (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, parent)
            try stmt.bind(2, parentId)
        }) { (stmt:SQLiteStmt, r:Int) -> () in
            entities.append(
                ImageEntity(
                    id: stmt.columnInt(0),
                    parent: stmt.columnText(1),
                    parentId: stmt.columnInt(2),
                    path: stmt.columnText(3),
                    ext: stmt.columnText(4),
                    originalName: stmt.columnText(5),
                    userId: stmt.columnInt(6),
                    createdAt: stmt.columnText(7),
                    updatedAt: stmt.columnText(8)
                )
            )
        }
        
        return entities
    }
}
