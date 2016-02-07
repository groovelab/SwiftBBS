//
//  AuthHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/08.
//	Copyright GrooveLab
//
//

import Foundation
import PerfectLib

class AuthHandler : BaseRequestHandler {
    //  MARK: life cycle
    override init() {
        super.init()
        
        //  define action acl
        //        needLoginActions = []
        //        redirectUrlIfNotLogin = "/"
        
        noNeedLoginActions = ["github"]
        redirectUrlIfLogin = "/"
    }
    
    override func dispatchAction(action: String) throws -> ActionResponse {
        switch request.action {
        case "callback":
            return try callbackAction()
        case "github":
            return try githubAction()
        default:
            return try githubAction()   //  TODO
        }
    }
    
    //  MARK: actions
    func githubAction() throws -> ActionResponse {
        //  TODO: add state(ramdom string)
        let authUrl = "https://github.com/login/oauth/authorize?client_id=\(Config.gitHubClientId)"
        
        return .Redirect(url: authUrl)
    }
    
    func callbackAction() throws -> ActionResponse {
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get code")
        }
        
        guard let accessToken = try getGithubAccessToken(code: code) else {
            return .Error(status: 500, message:"can not get access token")
        }
        guard let githubUser = try getGithubUser(accessToken) else {
            return .Error(status: 500, message:"can not get user")
        }
        
        
        //  check if already stored provider user id in user table
        if let userEntity = try userRepository.findByProviderId(githubUser.id, provider: "github"), userId = userEntity.id {
            //  update user data
            let userEntity = UserEntity(id: userId, provider: "github", providerUserId: githubUser.id, providerUserName: githubUser.name)
            try userRepository.update(userEntity)
            
            //  login
            session["id"] = userId
        } else {
            //  store provider user id into user table
            let userEntity = UserEntity(id: nil, provider: "github", providerUserId: githubUser.id, providerUserName: githubUser.name)
            try userRepository.insert(userEntity)
            
            //  login
            let userId = userRepository.lastInsertId()
            session["id"] = userId
        }
        
        return .Redirect(url: "/user/mypage")
    }
    
    private func getGithubAccessToken(code code: String) throws -> String? {
        let url = "https://github.com/login/oauth/access_token"
        let responseBody = curl(url, header: "Accept: application/json", postParams: [
            "client_id": Config.gitHubClientId,
            "client_secret": Config.gitHubClientSecret,
            "code": code
            ])
        
        let jsonDecoded = try JSONDecoder().decode(responseBody)
        guard let jsonMap = jsonDecoded as? JSONDictionaryType else { return nil }
        
        /*
        response example
        success : {"access_token":"hoge","token_type":"bearer","scope":""}
        error   : {"error":"bad_verification_code","error_description":"The code passed is incorrect or expired.","error_uri":"https://developer.github.com/v3/oauth/#bad-verification-code"}
        */
        
        return jsonMap["access_token"] as? String
    }
    
    private func getGithubUser(accessToken: String) throws -> (id: String, name: String)? {
        let url = "https://api.github.com/user?access_token=\(accessToken)"
        let responseBody = curl(url, header: "User-Agent: Awesome-Octocat-App")
        
        let jsonDecoded = try JSONDecoder().decode(responseBody)
        guard let jsonMap = jsonDecoded as? JSONDictionaryType else { return nil }
        guard let id = jsonMap["id"] as? Int else { return nil }
        guard let name = jsonMap["login"] as? String else { return nil }
        
        return (id: String(id), name: name)
    }
    
    private func curl(url: String, header: String?, postParams: [String: String]? = nil) -> String {
        let task = NSTask()
        task.launchPath = Config.curlDir + "curl"
        var arguments = [url, "-s"]
        if let header = header {
            arguments.append("-H")
            arguments.append(header)
        }
        if let postParams = postParams {
            postParams.forEach({ key, value in
                arguments.append("-d")
                arguments.append("\(key)=\(value)")
            })
        }
        task.arguments  = arguments
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        
        return String(data: output, encoding: NSUTF8StringEncoding) ?? ""
    }
}
