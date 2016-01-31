//
//  BbsHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//

import PerfectLib


enum ValidatorError : ErrorType {
    case Invalid(String)
}

protocol Validator {
    func validate(value: Any?) throws
}

class ValidatorManager : Validator {
    var validators = [Validator]()
    var errorMessages = [String]()
    
    func validate(value: Any?) throws {
        try validators.forEach { (validator) in
            do {
                try validator.validate(value)
            } catch ValidatorError.Invalid(let msg) {
                errorMessages.append(msg)
            }
        }
        
        if errorMessages.count > 0 {
            throw ValidatorError.Invalid(errorMessages.description)
        }
    }
}

class RequiredValidator : Validator {
    var errorMessage = "required"
    
    func validate(value: Any?) throws {
        guard let value = value else {
            throw ValidatorError.Invalid(errorMessage)
        }
        
        if let string = value as? String where string.characters.count == 0 {
            throw ValidatorError.Invalid(errorMessage)
        }
    }
}

class LengthValidator : Validator {
    var min: Int?
    var max: Int?
    
    var errorMessageShorter: String {
        return "min length is \(min!)"
    }
    var errorMessageLonger: String {
        return "max length is \(max!)"
    }

    convenience init(min: Int, max: Int) {
        self.init()
        self.min = min
        self.max = max
    }
    
    convenience init(min: Int) {
        self.init()
        self.min = max
    }
    
    convenience init(max: Int) {
        self.init()
        self.max = max
    }
    
    func validate(value: Any?) throws {
        guard let value = value as? String else {
            return
        }
        
        if let min = min where value.characters.count < min {
            throw ValidatorError.Invalid(errorMessageShorter)
        } else if let max = max where value.characters.count > max {
            throw ValidatorError.Invalid(errorMessageLonger)
        }
    }
}



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
        let title = request.param("title")
        let comment = request.param("comment")
        
        //  validate
        let titleValidatorManager = ValidatorManager()
        titleValidatorManager.validators.append(RequiredValidator())
        titleValidatorManager.validators.append(LengthValidator(max: 100))
        do {
            try titleValidatorManager.validate(title)
        } catch ValidatorError.Invalid(let message) {
            return .Error(status: 500, message: "invalidate request parameter title:" + message)
        }
        
        let commentvalidatorManager = ValidatorManager()
        commentvalidatorManager.validators.append(RequiredValidator())
        commentvalidatorManager.validators.append(LengthValidator(max: 1000))
        do {
            try commentvalidatorManager.validate(comment)
        } catch ValidatorError.Invalid(let message) {
            return .Error(status: 500, message: "invalidate request parameter title:" + message)
        }

        let fileUploads = request.fileUploads
        let image = fileUploads.filter { (uploadFile) -> Bool in
            return uploadFile.fieldName == "image"
        }.first
        //  TODO: validate image (ex.mime type or file size)
        
        //  insert  TODO: begin transaction
        let entity = BbsEntity(id: nil, title: title!, comment: comment!, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
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
