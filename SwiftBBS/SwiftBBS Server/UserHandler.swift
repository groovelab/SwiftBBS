//
//  UserHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
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
    
    override func dispatchAction(action: String) throws -> ActionResponse {
        switch request.action {
        case "login" where request.requestMethod() == "POST":
            return try doLoginAction()
        case "login":
            return try loginAction()
        case "logout":
            return try logoutAction()
        case "register" where request.requestMethod() == "POST":
            return try doRegisterAction()
        case "register":
            return try registerAction()
        case "edit" where request.requestMethod() == "POST":
            return try doEditAction()
        case "edit":
            return try editAction()
        case "delete" where request.requestMethod() == "POST":
            return try doDeleteAction()
        default:
            return try mypageAction()
        }
    }
    
    //  MARK: actions
    func mypageAction() throws -> ActionResponse {
        return .Output(templatePath: "user_mypage.mustache", values: [String: Any]())
    }
    
    func editAction() throws -> ActionResponse {
        return .Output(templatePath: "user_edit.mustache", values: [String: Any]())
    }
    
    func doEditAction() throws -> ActionResponse {
        //  validate TODO:create validaotr
        guard let name = request.param("name") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        
        let password = request.param("password") ?? ""
        
        //  update
        guard let beforeUserEntity = try getUser(userIdInSession()) else {
            return .Error(status: 404, message: "not found user")
        }
        
        let userEntity = UserEntity(id: beforeUserEntity.id, name: name, password: password, createdAt: nil, updatedAt: nil)
        try userReposity.update(userEntity)
        
        if request.acceptJson {
            var values = [String: Any]()
            values["status"] = "success"
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/user/mypage")
        }
    }
    
    func doDeleteAction() throws -> ActionResponse {
        //  delete
        guard let userEntity = try getUser(userIdInSession()) else {
            return .Error(status: 404, message: "not found user")
        }
        
        try userReposity.delete(userEntity)
        logout()
        
        if request.acceptJson {
            var values = [String: Any]()
            values["status"] = "success"
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/bbs")
        }
    }
    
    func registerAction() throws -> ActionResponse {
        return .Output(templatePath: "user_register.mustache", values: [String: Any]())
    }
    
    func doRegisterAction() throws -> ActionResponse {
        //  validate TODO:create validaotr
        guard let name = request.param("name") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        guard let password = request.param("password") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        
        //  insert
        let userEntity = UserEntity(id: nil, name: name, password: password, createdAt: nil, updatedAt: nil)
        try userReposity.insert(userEntity)
        
        //  do login
        let isLoginSuccess = try login(name, password: password)
        if request.acceptJson {
            var values = [String: Any]()
            values["status"] = isLoginSuccess ? "success" : "failed"
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: isLoginSuccess ? "/bbs" : "/user/login")  ///  TODO:add login success or failed message
        }
    }
    
    func loginAction() throws -> ActionResponse {
        return .Output(templatePath: "user_login.mustache", values: [String: Any]())
    }
    
    func doLoginAction() throws -> ActionResponse {
        //  validate
        guard let name = request.param("name") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        guard let password = request.param("password") else {
            return .Error(status: 500, message: "invalidate request parameter")
        }
        
        //  check exist
        let isLoginSuccess = try login(name, password: password)
        if request.acceptJson {
            var values = [String: Any]()
            values["status"] = isLoginSuccess ? "success" : "failed"
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: isLoginSuccess ? "/bbs" : "/user/login")  ///  TODO:add login success or failed message
        }
    }
    
    func logoutAction() throws -> ActionResponse {
        logout()
        
        if request.acceptJson {
            var values = [String: Any]()
            values["status"] = "success"
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/user/login")
        }
    }
    
    //  TODO:create authenticator
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
