//
//  UserHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//  Copyright GrooveLab
//

import PerfectLib

class UserHandler: BaseRequestHandler {
    //  MARK: forms
    class RegisterForm : FormType {
        var name: String!
        var password: String!
        var password2: String!
        
        var validationRules: ValidatorManager.ValidationKeyAndRules {
            return [
                "name": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: nil),
                ],
                "password": [
                    ValidationType.Required,
                    ValidationType.Length(min: 8, max: nil),
                ],
                "password2": [
                    ValidationType.Required,
                    ValidationType.Length(min: 8, max: nil),
                    ValidationType.Identical(targetKey: "password")
                ],
            ]
        }
        
        subscript (key: String) -> Any? {
            get { return nil } //  not use
            set {
                switch key {
                case "name": name = newValue! as! String
                case "password": password = newValue! as! String
                case "password2": password2 = newValue! as! String
                default: break
                }
            }
        }
    }
    
    class EditForm : FormType {
        var name: String!
        var password: String?
        var password2: String?

        var validationRules: ValidatorManager.ValidationKeyAndRules {
            return [
                "name": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: nil),
                ],
                "password": [
                    ValidationType.Length(min: 8, max: nil),
                ],
                "password2": [
                    ValidationType.Length(min: 8, max: nil),
                    ValidationType.Identical(targetKey: "password")
                ],
            ]
        }
        
        subscript (key: String) -> Any? {
            get { return nil } //  not use
            set {
                switch key {
                case "name": name = newValue! as! String
                case "password": password = newValue as? String
                case "password2": password2 = newValue as? String
                default: break
                }
            }
        }
    }
    
    class LoginForm : FormType {
        var name: String!
        var password: String!
        
        var validationRules: ValidatorManager.ValidationKeyAndRules {
            return [
                "name": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: nil),
                ],
                "password": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: nil),
                ],
            ]
        }
        
        subscript (key: String) -> Any? {
            get { return nil } //  not use
            set {
                switch key {
                case "name": name = newValue! as! String
                case "password": password = newValue! as! String
                default: break
                }
            }
        }
    }

    class ApnsDeviceTokenForm : FormType {
        var devieToken: String!
        
        var validationRules: ValidatorManager.ValidationKeyAndRules {
            return [
                "device_token": [
                    ValidationType.Required,
                    ValidationType.Length(min: 1, max: 200),
                ],
            ]
        }
        
        subscript (key: String) -> Any? {
            get { return nil } //  not use
            set {
                switch key {
                case "device_token": devieToken = newValue! as! String
                default: break
                }
            }
        }
    }

    //  MARK: life cycle
    override init() {
        super.init()
        
        //  define action acl
        needLoginActions = ["index", "mypage", "logout", "edit", "delete", "device_token"]
        redirectUrlIfNotLogin = "/user/login"
        
        noNeedLoginActions = ["login", "add"]
        redirectUrlIfLogin = "/"
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
        case "apns_device_token" where request.requestMethod() == "POST":
            return try doApnsDeviceTokenAction()
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
        var form = EditForm()
        do {
            try form.validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.description)
        }
        
        //  update
        let userEntity = UserEntity(id: try userIdInSession(), name: form.name, password: form.password)
        try userRepository.update(userEntity)
        
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
        
        try userRepository.delete(userEntity)
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
        var form = RegisterForm()
        do {
            try form.validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.description)
        }
        
        //  insert
        let userEntity = UserEntity(id: nil, name: form.name, password: form.password)
        try userRepository.insert(userEntity)
        
        //  do login
        let isLoginSuccess = try login(form.name, password: form.password)
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
        var form = LoginForm()
        do {
            try form.validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.description)
        }
        
        //  check exist
        let isLoginSuccess = try login(form.name, password: form.password)
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
    
    func doApnsDeviceTokenAction() throws -> ActionResponse {
        var form = ApnsDeviceTokenForm()
        do {
            try form.validate(request)
        } catch let error as FormError {
            return .Error(status: 500, message: "invalidate request parameter. " + error.description)
        }
        
        //  update
        var userEntity = try getUser(userIdInSession())!
        userEntity.apnsDeviceToken = form.devieToken
        try userRepository.update(userEntity)
        
        if request.acceptJson {
            var values = [String: Any]()
            values["status"] = "success"
            return .Output(templatePath: nil, values: values)
        } else {
            return .Redirect(url: "/user/mypage")
        }
    }
    
    //  TODO: create UserService with login method
    private func login(name: String, password: String) throws -> Bool {
        if let userEntity = try userRepository.findByName(name, password: password), let userId = userEntity.id {
            //  success login
            session["id"] = String(userId)
            return true
        } else {
            return false
        }
    }
    
    //  TODO: create UserService with logout method
    private func logout() {
        session["id"] = nil
    }
}
