//
//  BaseRequestHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//  Copyright GrooveLab
//

import PerfectLib
import MySQL

class BaseRequestHandler: RequestHandler {
    enum ActionResponse {
        case Output(templatePath: String?, values: [String: Any])
        case Redirect(url: String)
        case Error(status: Int, message: String)
    }
    
    //  action acl
    enum ActionAcl {
        case NeedLogin
        case NoNeedLogin
        case None
    }
    
    var needLoginActions: [String] = []
    var noNeedLoginActions: [String] = []
    var redirectUrlIfLogin: String?
    var redirectUrlIfNotLogin: String?

    var request: WebRequest!
    var response: WebResponse!
//    var db: SQLite!
    var db: MySQL!
    var session: SessionManager!
    
    lazy var selectOption: SelectOption = SelectOption(page: self.request.param("page"), rows: self.request.param("rows"))
    lazy var userRepository: UserRepository = UserRepository(db: self.db)

    func handleRequest(request: WebRequest, response: WebResponse) {
        //  initialize
        self.request = request
        self.response = response
        
        defer {
            response.requestCompletedCallback()
        }
        
        do {
//            db = try SQLite(Config.sqliteDbPath)
            let dbManager = try DatabaseManager()
            db = dbManager.db

            session = try response.getSession(Config.sessionName, withConfiguration: SessionConfiguration(Config.sessionName, expires: Config.sessionExpires))
            
            switch try checkActionAcl() {
            case .NeedLogin:
                if let redirectUrl = redirectUrlIfNotLogin {
                    if request.acceptJson {
                        response.setStatus(403, message: "need login")
                    } else {
                        response.redirectTo(redirectUrl)
                    }
                    return
                }
            case .NoNeedLogin:
                if let redirectUrl = redirectUrlIfLogin {
                    if request.acceptJson {
                        response.setStatus(403, message: "need login")
                    } else {
                        response.redirectTo(redirectUrl)
                    }
                    return
                }
            case .None:
                break
            }
            
            switch try dispatchAction(request.action) {
            case let .Output(templatePath, responseValues):
                var values = responseValues
                try setLoginUser(&values)   //  set user info if logged
                
                if request.acceptJson {
                    try response.outputJson(values)
                } else if let templatePath = templatePath {
                    try response.renderHTML(templatePath, values: values)
                }
            case let .Redirect(url):
                response.redirectTo(url)
            case let .Error(status, message):
                response.setStatus(status, message: message)
                break;
            }
        } catch let e {
            print(e)
        }
    }
    
    func dispatchAction(action: String) throws -> ActionResponse {
        //  need implement in subclass
        return .Error(status: 500, message: "need implement")
    }
    
    func userIdInSession() throws -> UInt? {
        guard let userIdString = session["id"] as? String, let userId = UInt(userIdString) else {
            return nil
        }
        
        //  check user table if exists
        guard let _ = try getUser(userId) else {
            return nil
        }
        
        return userId
    }
    
    func getUser(userId: UInt?) throws -> UserEntity? {
        guard let userId = userId else {
            return nil
        }
        
        return try userRepository.findById(userId)
    }
    
    func setLoginUser(inout values: [String: Any]) throws {
        if let loginUser = try getUser(userIdInSession()) {
            values["loginUser"] = loginUser.toDictionary()
        }
    }

    private func checkActionAcl() throws -> ActionAcl {
        if let _ = try userIdInSession() {
            //  already login
            if noNeedLoginActions.contains(request.action) {
                return .NoNeedLogin
            }
        } else {
            //  not yet login
            if needLoginActions.contains(request.action) {
                return .NeedLogin
            }
        }
        
        return .None
    }
}

