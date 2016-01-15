//
//  UserHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//
//

import PerfectLib

class UserHandler: BaseRequestHandler {
    override init() {
        super.init()
        
        //  define action acl
        needLoginActions = ["index", "mypage", "logout", "edit", "delete"]
        redirectUrlIfNotLogin = "/user/login"
        
        noNeedLoginActions = ["login", "add"]
        redirectUrlIfLogin = "/bbs"
    }
    
    override func dispatchAction(action: String) throws {
        switch request.action {
        case "login" where request.requestMethod() == "POST":
            try doLoginAction()
        case "login":
            try loginAction()
        case "logout":
            try logoutAction()
        case "register" where request.requestMethod() == "POST":
            try doRegisterAction()
        case "register":
            try registerAction()
        case "edit" where request.requestMethod() == "POST":
            try doEditAction()
        case "edit":
            try editAction()
        case "delete" where request.requestMethod() == "POST":
            try doDeleteAction()
        default:
            try mypageAction()
        }
    }
    
    //  MARK: actions
    func mypageAction() throws {
        var values = MustacheEvaluationContext.MapType()
        
        //  show user info if logged
        try setLoginUser(&values)
        try response.renderHTML("user_mypage.mustache", values: values)
    }
    
    //  TODO:adopt ajax
    func editAction() throws {
        var values = MustacheEvaluationContext.MapType()
        
        //  show user info if logged
        try setLoginUser(&values)
        try response.renderHTML("user_edit.mustache", values: values)
    }
    
    func doEditAction() throws {
        //  validate TODO:create validaotr
        guard let name = request.param("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        let password = request.param("password") ?? ""  //  TODO: enctypt
        
        //  update
        guard let beforeUserEntity = try getUser(userIdInSession()) else {
            response.setStatus(404, message: "not found user")
            return
        }
        
        let userEntity = UserEntity(id: beforeUserEntity.id, name: name, password: password, createdAt: nil, updatedAt: nil)
        try userReposity.update(userEntity)
        
        response.redirectTo("/user/mypage")
    }
    
    func doDeleteAction() throws {
        //  delete
        guard let userEntity = try getUser(userIdInSession()) else {
            response.setStatus(404, message: "not found user")
            return
        }
        
        try userReposity.delete(userEntity)
        logout()
        
        response.redirectTo("/bbs")
    }
    
    func registerAction() throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user_register.mustache", values: values)
    }
    
    func doRegisterAction() throws {
        //  validate TODO:create validaotr
        guard let name = request.param("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let password = request.param("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        let userEntity = UserEntity(id: nil, name: name, password: password, createdAt: nil, updatedAt: nil)
        try userReposity.insert(userEntity)
        
        //  do login
        if try login(name, password: password) {
            response.redirectTo("/bbs") //  TODO:add login success message
        } else {
            response.redirectTo("/user/login")  //  TODO:add success message
        }
    }
    
    func loginAction() throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user_login.mustache", values: values)
    }
    
    func doLoginAction() throws {
        //  validate
        guard let loginName = request.param("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let loginPassword = request.param("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  check exist
        if try login(loginName, password: loginPassword) {
            response.redirectTo("/bbs") //  TODO:add login success message
        } else {
            response.redirectTo("/user/login")  //  TODO:add login failed message
        }
    }
    
    func logoutAction() throws {
        logout()
        
        response.redirectTo("/user/login")
    }
    
    private func login(name: String, password: String) throws -> Bool {
        if let userEntity = try userReposity.findByName(name, password: password), let userId = userEntity.id {
            //  success login
            let session = self.response.getSession(Config.sessionName)
            session["id"] = userId
            return true
        } else {
            return false
        }
    }
    
    private func logout() {
        let session = self.response.getSession(Config.sessionName)
        session["id"] = nil
    }
}
