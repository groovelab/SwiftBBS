//
//  BbsHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//
//

import PerfectLib

class BbsHandler: BaseRequestHandler {
    
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
        let bbsEntities = try bbsReposity.selectByKeyword(keyword)
        
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
        
        //  insert  TODO:add image
        let entity = BbsEntity(id: nil, title: title, comment: comment, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
        try bbsReposity.insert(entity)
        
        let bbsId = bbsReposity.lastInsertId()
        
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
        guard let bbsEntity = try bbsReposity.findById(bbsId) else {
            return .Error(status: 404, message: "not found bbs")
        }
        var dictionary = bbsEntity.toDictionary()
        dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
        values["bbs"] = dictionary
        
        //  bbs post
        let bbsCommentEntities = try bbsCommentReposity.selectByBbsId(bbsId)
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
        try bbsCommentReposity.insert(entity)
        
        if request.acceptJson {
            var values = [String: Any]()
            values["commentId"] = bbsCommentReposity.lastInsertId()
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/bbs/detail/\(entity.bbsId)")
        }
    }
}
