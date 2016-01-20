//
//  BbsHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import Foundation
import PerfectLib

class BbsHandler: BaseRequestHandler {
    //  repository
    lazy var bbsRepository: BbsRepository = BbsRepository(db: self.db)
    lazy var bbsCommentRepository: BbsCommentRepository = BbsCommentRepository(db: self.db)
    lazy var imageRepository: ImageRepository = ImageRepository(db: self.db)

    override init() {
        super.init()
        
        //  define action acl
        needLoginActions = ["add", "addcomment"]
        redirectUrlIfNotLogin = "/user/login"
        
        //        noNeedLoginActions = []
        //        redirectUrlIfLogin = "/"
    }
    
    override func dispatchAction(action: String) throws -> ActionResponse {
        switch request.action {
        case "add" where request.requestMethod() == "POST":
            return try addAction()
        case "addcomment" where request.requestMethod() == "POST":
            return try addcommentAction()
        case "detail":
            return try detailAction()
        default:
            return try listAction()
        }
    }
    
    //  MARK: actions
    func listAction() throws -> ActionResponse {
        let keyword = request.param("keyword")
        let bbsEntities = try bbsRepository.selectByKeyword(keyword)
        
        var values = [String: Any]()
        
        values["keyword"] = keyword ?? ""
        if request.acceptJson {
            var bbsList = [Any]()
            bbsEntities.forEach({ (entity) in
                bbsList.append(entity.toDictionary())
            })
            values["bbsList"] = bbsList
        } else {
            values["bbsList"] = bbsEntities.map({ (bbsEntity) -> [String: Any] in
                var dictionary = bbsEntity.toDictionary()
                dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
                return dictionary
            })
        }
        
        return .Output(templatePath: "bbs_list.mustache", values: values)
    }
    
    func addAction() throws -> ActionResponse {
        //  validate
        guard let title = request.param("title") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        guard let comment = request.param("comment") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        let fileUploads = request.fileUploads
        let image = fileUploads.filter { (uploadFile) -> Bool in
            return uploadFile.fieldName == "image"
        }.first
        //  TODO: validate image (ex.mime type or file size)
        
        //  insert  TODO: begin transaction
        let entity = BbsEntity(id: nil, title: title, comment: comment, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
        try bbsRepository.insert(entity)
        
        let bbsId = bbsRepository.lastInsertId()
        
        //  add image
        if let image = image {
            if let fileName = ImageEntity.fileName(fromPath: image.tmpFileName), let ext = ImageEntity.fileExtension(image.fileName) {
                let path = fileName + "." + ext
                try File(image.tmpFileName).copyTo(Config.uploadDirPath + path)
            
                let imageEntity = ImageEntity(id: nil, parent: "bbs", parentId: bbsId, path: path, ext: ext, originalName: image.fileName, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
                try imageRepository.insert(imageEntity)   //  TODO: delete file if catch exception
            }
        }
        
        if request.acceptJson {
            var values = [String: Any]()
            values["bbsId"] = bbsId
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/bbs/detail/\(bbsId)")
        }
    }
    
    func detailAction() throws -> ActionResponse {
        guard let bbsIdString = request.urlVariables["id"], let bbsId = Int(bbsIdString) else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        
        var values = [String: Any]()
        
        //  bbs
        guard let bbsEntity = try bbsRepository.findById(bbsId) else {
            return .Error(status: 404, message: "not found bbs")
        }
        var dictionary = bbsEntity.toDictionary()
        if request.acceptJson == false {
            dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
        }
        values["bbs"] = dictionary
        
        //  bbs image
        let imageEntities = try imageRepository.selectBelongTo(parent:"bbs", parentId: bbsEntity.id)
        if let imageEntity = imageEntities.first {
            var dictionary = imageEntity.toDictionary()
            dictionary["url"] = Config.uploadDirUrl + (dictionary["path"] as! String)
            values["image"] = dictionary
        }
        
        //  bbs post
        let bbsCommentEntities = try bbsCommentRepository.selectByBbsId(bbsId)
        if request.acceptJson {
            var comments = [Any]()
            bbsCommentEntities.forEach({ (entity) in
                comments.append(entity.toDictionary())
            })
            values["comments"] = comments
        } else {
            values["comments"] = bbsCommentEntities.map({ (entity) -> [String: Any] in
                var dictionary = entity.toDictionary()
                dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
                return dictionary
            })
        }
        
        return .Output(templatePath: "bbs_detail.mustache", values: values)
    }
    
    func addcommentAction() throws -> ActionResponse {
        //  validate
        guard let bbsIdString = request.param("bbs_id"), let bbsId = Int(bbsIdString) else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        guard let comment = request.param("comment") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        
        //  insert
        let entity = BbsCommentEntity(id: nil, bbsId: bbsId, comment: comment, userId: try userIdInSession()!, createdAt: nil, updatedAt: nil)
        try bbsCommentRepository.insert(entity)
        
        if request.acceptJson {
            var values = [String: Any]()
            values["commentId"] = bbsCommentRepository.lastInsertId()
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/bbs/detail/\(entity.bbsId)")
        }
    }
}
