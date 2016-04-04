//
//  BbsHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//  Copyright GrooveLab
//

import PerfectLib

class BbsHandler: BaseRequestHandler {
    //  MARK: repositories
    lazy var bbsRepository: BbsRepository = BbsRepository(db: self.db)
    lazy var bbsCommentRepository: BbsCommentRepository = BbsCommentRepository(db: self.db)
    lazy var imageRepository: ImageRepository = ImageRepository(db: self.db)
    
    //  MARK: forms
    class AddForm : FormType {
        var title: String!
        var comment: String!
        var image: MimeReader.BodySpec?

        var validationRules: ValidatorManager.ValidationKeyAndRules {
            return [
                "title": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: 100)
                ],
                "comment": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: 1000)
                ],
                "image": [
                    ValidationType.Image(fileSize: Config.uploadImageFileSize, fileExtensions: Config.uploadImageFileExtensions)
                ]
            ]
        }

        subscript (key: String) -> Any? {
            get { return nil } //  not use
            set {
                switch key {
                case "title": title = newValue! as! String
                case "comment": comment = newValue! as! String
                case "image": image = newValue as? MimeReader.BodySpec
                default: break
                }
            }
        }
    }

    class AddCommentForm : FormType {
        var bbsId: UInt!
        var comment: String!
        
        var validationRules: ValidatorManager.ValidationKeyAndRules {
            return [
                "bbs_id": [
                    ValidationType.Required,
                    ValidationType.UInteger(min: 1, max: nil)
                ],
                "comment": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: 1000)
                ],
            ]
        }

        subscript (key: String) -> Any? {
            get { return nil } //  not use
            set {
                switch key {
                case "bbs_id": bbsId = newValue! as! UInt
                case "comment": comment = newValue! as! String
                default: break
                }
            }
        }
    }
    
    //  MARK: life cycle
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
        
        if request.acceptJson {
            values["bbsList"] = bbsEntities.map({ (bbsEntity) -> [String: Any] in
                return bbsEntity.toDictionary()
            }) as [Any]
        } else {
            values["bbsList"] = bbsEntities.map({ (bbsEntity) -> [String: Any] in
                var dictionary = bbsEntity.toDictionary()
                if !request.acceptJson {
                    dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
                }
                return dictionary
            })
        }
        
        let totalCount = try bbsRepository.countByKeyword(keyword)
        values["pager"] = Pager(totalCount: totalCount, selectOption: selectOption).toDictionary(request.acceptJson)
        
        return .Output(templatePath: "bbs_list.mustache", values: values)
    }
    
    func addAction() throws -> ActionResponse {
        var form = AddForm()
        do {
            try form.validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.description)
        }
        
        //  insert  TODO: begin transaction
        let entity = BbsEntity(id: nil, title: form.title, comment: form.comment, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
        let bbsId = try bbsRepository.insert(entity)
        
        //  add image
        if let image = form.image {
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
        guard let bbsIdString = request.urlVariables["id"], let bbsId = UInt(bbsIdString) else {
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
        
        if request.acceptJson {
            values["comments"] = bbsCommentEntities.map({ (entity) -> [String: Any] in
                return entity.toDictionary()
            }) as [Any]
        } else {
            values["comments"] = bbsCommentEntities.map({ (entity) -> [String: Any] in
                var dictionary = entity.toDictionary()
                if !request.acceptJson {
                    dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
                }
                return dictionary
            })
        }
        
        return .Output(templatePath: "bbs_detail.mustache", values: values)
    }
    
    func addcommentAction() throws -> ActionResponse {
        var form = AddCommentForm()
        do {
            try form.validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.description)
        }
        
        //  TODO: if bbs exists
        
        //  insert
        let entity = BbsCommentEntity(id: nil, bbsId: form.bbsId, comment: form.comment, userId: try userIdInSession()!, createdAt: nil, updatedAt: nil)
        let commentId = try bbsCommentRepository.insert(entity)
        
        //  notify
        //try notifyBbsCommented(entity.bbsId, exceptUserId: entity.userId)
        
        if request.acceptJson {
            var values = [String: Any]()
            values["commentId"] = commentId
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/bbs/detail/\(entity.bbsId)")
        }
    }
}
