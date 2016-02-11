//
//  AuthHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/08.
//	Copyright GrooveLab
//
//

import PerfectLib
import cURL

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
        /*
        response example
        success : {"access_token":"hoge","token_type":"bearer","scope":""}
        error   : {"error":"bad_verification_code","error_description":"The code passed is incorrect or expired.","error_uri":"https://developer.github.com/v3/oauth/#bad-verification-code"}
        */
        guard let jsonObject = try curl(url, header: "Accept: application/json", postParams: [
            "client_id": Config.gitHubClientId,
            "client_secret": Config.gitHubClientSecret,
            "code": code
        ]) else { return nil }
        
        guard let jsonMap = jsonObject as? [String: Any], let accessToken = jsonMap["access_token"] as? String else { return nil }
        return accessToken
        
    }
    
    private func getGithubUser(accessToken: String) throws -> (id: String, name: String)? {
        let url = "https://api.github.com/user?access_token=\(accessToken)"
        /*
        response example
        {"login":"user name","id":7554889}
        */
        guard let jsonObject = try curl(url, header: "User-Agent: Awesome-Octocat-App") else { return nil }
        guard let jsonMap = jsonObject as? [String: Any], let id = jsonMap["id"] as? Int, let name = jsonMap["login"] as? String else { return nil }

        return (id: String(id), name: name)
    }
    
    private func curl(url: String, header: String?, postParams: [String: String]? = nil) throws -> JSONConvertible? {
        let curl = CURL(url: url)
//        curl.setOption(CURLOPT_VERBOSE, int: 1)
        if let header = header {
            curl.setOption(CURLOPT_HTTPHEADER, s: header)
        }

        var byteArray = [UInt8]()
        if let postParams = postParams {
            curl.setOption(CURLOPT_POST, int: 1)
            let postParamString = postParams.map({ key, value in
                return "\(key)=\(value)"
            }).joinWithSeparator("&")
            byteArray = UTF8Encoding.decode(postParamString)
            curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutablePointer<UInt8>(byteArray))
            curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        }

        let response = curl.performFully()
        let responseBody = UTF8Encoding.encode(response.2)
//        print(response.0)
//        print(UTF8Encoding.encode(response.1))
//        print(responseBody)
        
        return try responseBody.jsonDecode()
    }
}
