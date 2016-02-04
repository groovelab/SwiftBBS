//
//  BbsHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import PerfectLib

class BbsHandler: BaseRequestHandler {
    //  repository
    lazy var bbsRepository: BbsRepository = BbsRepository(db: self.db)
    lazy var bbsCommentRepository: BbsCommentRepository = BbsCommentRepository(db: self.db)
    lazy var imageRepository: ImageRepository = ImageRepository(db: self.db)
    
    //  form
    struct AddForm : FormType {
        var validatorSetting: [String: [String]] {
            return [
                "title" : ["required", "length,1,100"],
                "comment": ["required", "length,1,1000"],
                "image": ["image,\(Config.uploadImageFileSize),\(Config.uploadImageFileExtensions.joinWithSeparator(","))"],
            ]
        }
    }
    
    struct AddCommentForm : FormType {
        var validatorSetting: [String: [String]] {
            return [
                "bbs_id" : ["required", "int,1,n"],
                "comment": ["required", "length,1,1000"],
            ]
        }
    }

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
        let bbsEntities = try bbsRepository.selectByKeyword(keyword, selectOption: selectOption)
        
        var values = [String: Any]()
        values["keyword"] = keyword ?? ""
        values["bbsList"] = bbsEntities.map({ (bbsEntity) -> [String: Any] in
            var dictionary = bbsEntity.toDictionary()
            if !request.acceptJson {
                dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
            }
            return dictionary
        })
        
        let totalCount = try bbsRepository.countByKeyword(keyword)
        values["pager"] = Pager(totalCount: totalCount, selectOption: selectOption).toDictionary()
        
        return .Output(templatePath: "bbs_list.mustache", values: values)
    }
    
    func addAction() throws -> ActionResponse {
        let validatedValues: [String: Any]!
        do {
            validatedValues = try AddForm().validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.toString())
        }
        
        let title = validatedValues["title"] as! String
        let comment = validatedValues["comment"] as! String
        let image = validatedValues["image"] as? MimeReader.BodySpec

        //  insert  TODO: begin transaction
        let entity = BbsEntity(id: nil, title: title, comment: comment, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
        try bbsRepository.insert(entity)
        
        let bbsId = bbsRepository.lastInsertId()
        
        //  add image
        if let image = image {
            let imageService = ImageService(
                uploadedImage: image,
                uploadDirPath: request.docRoot + Config.uploadDirPath,
                repository: imageRepository
            )
            imageService.parent = .Bbs
            imageService.parentId = bbsId
            imageService.userId = try self.userIdInSession()!
            try imageService.save()    //  TODO: delete file if catch exception
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
        if !request.acceptJson {
            dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
        }
        values["bbs"] = dictionary
        
        //  bbs image
        let imageEntities = try imageRepository.selectBelongTo(parent:.Bbs, parentId: bbsEntity.id)
        if let imageEntity = imageEntities.first {
            var dictionary = imageEntity.toDictionary()
            dictionary["url"] = "/" + Config.uploadDirPath + (dictionary["path"] as! String)
            values["image"] = dictionary
        }
        
        //  bbs post
        let bbsCommentEntities = try bbsCommentRepository.selectByBbsId(bbsId)
        values["comments"] = bbsCommentEntities.map({ (entity) -> [String: Any] in
            var dictionary = entity.toDictionary()
            if !request.acceptJson {
                dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
            }
            return dictionary
        })
        
        return .Output(templatePath: "bbs_detail.mustache", values: values)
    }
    
    func addcommentAction() throws -> ActionResponse {
        let validatedValues: [String: Any]!
        do {
            validatedValues = try AddCommentForm().validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.toString())
        }
        
        let bbsId = validatedValues["bbs_id"] as! Int
        let comment = validatedValues["comment"] as! String
        
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
