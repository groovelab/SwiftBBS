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
    
    override func dispatchAction(action: String) throws {
        switch request.action {
        case "add" where request.requestMethod() == "POST":
            try addAction()
        case "addcomment" where request.requestMethod() == "POST":
            try addcommentAction()
        case "detail":
            try detailAction()
        default:
            try listAction()
        }
    }
    
    func listAction() throws {
        let keyword = request.param("keyword")
        let bbsEntities = try bbsReposity.selectByKeyword(keyword)
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["keyword"] = keyword ?? ""
        values["bbsList"] = bbsEntities.map({ (bbsEntity) -> [String: Any] in
            var dictionary = bbsEntity.toDictionary()
            dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
            return dictionary
        })
        
        //  show user info if logged
        try setLoginUser(&values)
        try response.renderHTML("bbs_list.mustache", values: values)
    }
    
    func addAction() throws {
        //  validate
        guard let title = request.param("title") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let comment = request.param("comment") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert  TODO:add image
        let entity = BbsEntity(id: nil, title: title, comment: comment, userId: try self.userIdInSession()!, createdAt: nil, updatedAt: nil)
        try bbsReposity.insert(entity)
        
        let bbsId = bbsReposity.lastInsertId()
        response.redirectTo("/bbs/detail/\(bbsId)")
    }
    
    func detailAction() throws {
        guard let bbsIdString = request.urlVariables["id"], let bbsId = Int(bbsIdString) else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        var values = [String: Any]()
        
        //  bbs
        guard let bbsEntity = try bbsReposity.findById(bbsId) else {
            response.setStatus(404, message: "not found bbs")
            return
        }
        var dictionary = bbsEntity.toDictionary()
        dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
        values["bbs"] = dictionary
        
        //  bbs post
        let bbsCommentEntities = try bbsCommentReposity.selectByBbsId(bbsId)
        if request.acceptJson {
            var comments = [Any]()
            bbsCommentEntities.forEach({ (entity) in
                var dictionary = entity.toDictionary()
                dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
                comments.append(dictionary)
            })
            values["comments"] = comments
        } else {
            values["comments"] = bbsCommentEntities.map({ (entity) -> [String: Any] in
                var dictionary = entity.toDictionary()
                dictionary["comment"] = (dictionary["comment"] as! String).stringByEncodingHTML.htmlBrString
                return dictionary
            })
        }
        
        //  show user info if logged
        try setLoginUser(&values)
        
        if request.acceptJson {
            try response.outputJson(values)
        } else {
            try response.renderHTML("bbs_detail.mustache", values: values)
        }
    }
    
    func addcommentAction() throws {
        //  validate
        guard let bbsIdString = request.param("bbs_id"), let bbsId = Int(bbsIdString) else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let comment = request.param("comment") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        let entity = BbsCommentEntity(id: nil, bbsId: bbsId, comment: comment, userId: try userIdInSession()!, createdAt: nil, updatedAt: nil)
        try bbsCommentReposity.insert(entity)
        
        response.redirectTo("/bbs/detail/\(entity.bbsId)")
    }
}
