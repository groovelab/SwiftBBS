//
//  BaseRequestHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//
//

import PerfectLib

class BaseRequestHandler: RequestHandler {
    var request: WebRequest!
    var response: WebResponse!
    var db: SQLite!
    
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
    
    //  repository
    lazy var userReposity: UserRepository = UserRepository(db: self.db)
    lazy var bbsReposity: BbsRepository = BbsRepository(db: self.db)
    lazy var bbsCommentReposity: BbsCommentRepository = BbsCommentRepository(db: self.db)
    
    func userIdInSession() throws -> Int? {
        let session = response.getSession(Config.sessionName)
        guard let userId = session["id"] as? Int else {
            return nil
        }
        
        //  check user table if exists
        guard let _ = try getUser(userId) else {
            return nil
        }
        
        return userId
    }
    
    func getUser(userId: Int?) throws -> UserEntity? {
        guard let userId = userId else {
            return nil
        }
        
        return try userReposity.findById(userId)
    }
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        //  initialize
        self.request = request
        self.response = response
        
        defer {
            response.requestCompletedCallback()
        }
        
        do {
            db = try SQLite(Config.dbPath)
            try response.getSession(Config.sessionName, withConfiguration: SessionConfiguration(Config.sessionName, expires: 60))
            
            switch try checkActionAcl() {
            case .NeedLogin:
                if let redirectUrl = redirectUrlIfNotLogin {
                    response.redirectTo(redirectUrl)
                    return
                }
            case .NoNeedLogin:
                if let redirectUrl = redirectUrlIfLogin {
                    response.redirectTo(redirectUrl)
                    return
                }
            case .None:
                break
            }
            
            try dispatchAction(request.action)
        } catch (let e) {
            print(e)
        }
    }
    
    func dispatchAction(action: String) throws {
        //  need implement in subclass
    }
    
    func checkActionAcl() throws -> ActionAcl {
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
    
    func setLoginUser(inout values: MustacheEvaluationContext.MapType) throws {
        if let loginUser = try getUser(userIdInSession()) {
            values["loginUser"] = loginUser.toDictionary()
        }
    }
}

