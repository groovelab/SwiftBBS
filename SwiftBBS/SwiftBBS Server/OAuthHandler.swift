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

import Foundation

class OAuthHandler : BaseRequestHandler {
    typealias SocialUser = (id: String, name: String)
    private lazy var facebookRedirectUri: String = self.request.isHttps() ? "https" : "http" + "://\(self.request.httpHost())/oauth/facebook_callback"
    private lazy var googleRedirectUri: String = self.request.isHttps() ? "https" : "http" + "://\(self.request.httpHost())/oauth/google_callback"

    //  MARK: life cycle
    override init() {
        super.init()
        
        //  define action acl
        //        needLoginActions = []
        //        redirectUrlIfNotLogin = "/"
        
        noNeedLoginActions = ["github", "githubCallback", "facebook", "facebookCallback"]
        redirectUrlIfLogin = "/bbs"
    }
    
    override func dispatchAction(action: String) throws -> ActionResponse {
        switch request.action {
        case "github":
            return try githubAction()
        case "github_callback":
            return try githubCallbackAction()
        case "facebook":
            return try facebookAction()
        case "facebook_callback":
            return try facebookCallbackAction()
        case "google":
            return try googleAction()
        case "google_callback":
            return try googleCallbackAction()
        default:
            return .Redirect(url: "/")
        }
    }
    
    //  MARK: actions
    func googleAction() throws -> ActionResponse {
        //  TODO: add state
        let authUrl = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(Config.googleClientId)&response_type=code&scope=profile&redirect_uri=\(googleRedirectUri)"
        return .Redirect(url: authUrl)
    }
    
    func googleCallbackAction() throws -> ActionResponse {
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get facebook code")
        }
        guard let accessToken = try getGoogleAccessToken(code: code) else {
            return .Error(status: 500, message:"can not get facebook access token")
        }
        guard let googleUser = try getGoogleUser(accessToken) else {
            return .Error(status: 500, message:"can not get facebook user")
        }
        
        try loign(socialUser: googleUser, provider: .Google)
        return .Redirect(url: "/")
    }
    
    private func getGoogleAccessToken(code code: String) throws -> String? {
        let url = "https://www.googleapis.com/oauth2/v4/token"
        /*
        response example
        success : {"access_token": "hoge","token_type": "bearer", "expires_in":	1234, "id_token": "hoge"}
        error   : {"error": "error_message", "error_description": "Bad Request"}
        */
        guard let jsonObject = try curl(url, header: nil, postParams: [
            "code": code,
            "client_id": Config.googleClientId,
            "client_secret": Config.googleClientSecret,
            "redirect_uri": googleRedirectUri,
            "grant_type": "authorization_code"
        ]) else { return nil }
        guard let jsonMap = jsonObject as? [String: Any] else { return nil }
        guard let accessToken = jsonMap["access_token"] as? String else { return nil }
        return accessToken
    }
    
    private func getGoogleUser(accessToken: String) throws -> SocialUser? {
        let url = "https://www.googleapis.com/plus/v1/people/me?access_token=\(accessToken)"
        
        /*
        response example
        {"displayName":"user name", "id":"1"}
        */
        guard let jsonObject = try curl(url) else { return nil }
        guard let jsonMap = jsonObject as? [String: Any] else { return nil }
        guard let id = jsonMap["id"] as? String else { return nil}
        guard let name = jsonMap["displayName"] as? String else { return nil }
        return (id: id, name: name)
    }
    
    func facebookAction() throws -> ActionResponse {
        //  TODO: add state
        let authUrl = "https://www.facebook.com/dialog/oauth?client_id=\(Config.facebookAppId)&redirect_uri=\(facebookRedirectUri)"
        return .Redirect(url: authUrl)
    }
    
    func facebookCallbackAction() throws -> ActionResponse {
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get facebook code")
        }
        guard let accessToken = try getFacebookAccessToken(code: code) else {
            return .Error(status: 500, message:"can not get facebook access token")
        }
        guard let facebookUser = try getFacebookUser(accessToken) else {
            return .Error(status: 500, message:"can not get facebook user")
        }

        try loign(socialUser: facebookUser, provider: .Facebook)
        return .Redirect(url: "/")
    }
    
    private func getFacebookAccessToken(code code: String) throws -> String? {
        let url = "https://graph.facebook.com/v2.3/oauth/access_token?client_id=\(Config.facebookAppId)&redirect_uri=\(facebookRedirectUri)&client_secret=\(Config.facebookAppSecret)&code=\(code)"
        /*
        response example
        success : {"access_token": "hoge","token_type": "bearer", "expires_in":	1234}
        error   : {"error": {"code": "1", "message": "error message", "fbtrae_id": "", "type": "OAuthException"}}
        */
        guard let jsonObject = try curl(url) else { return nil }
        guard let jsonMap = jsonObject as? [String: Any] else { return nil }
        guard let accessToken = jsonMap["access_token"] as? String else { return nil }
        
        return accessToken
    }
    
    private func getFacebookUser(accessToken: String) throws -> SocialUser? {
        let url = "https://graph.facebook.com//v2.5/me?access_token=\(accessToken)"
        
        /*
        response example
        {"login":"user name","id":1}
        */
        guard let jsonObject = try curl(url) else { return nil }
        guard let jsonMap = jsonObject as? [String: Any] else { return nil }
        guard let id = jsonMap["id"] as? String else { return nil}
        guard let name = jsonMap["name"] as? String else { return nil }
        return (id: id, name: name)
    }
    
    func githubAction() throws -> ActionResponse {
        //  TODO: add state(ramdom string)
        let authUrl = "https://github.com/login/oauth/authorize?client_id=\(Config.gitHubClientId)"
        return .Redirect(url: authUrl)
    }
    
    func githubCallbackAction() throws -> ActionResponse {
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get github code")
        }
        guard let accessToken = try getGithubAccessToken(code: code) else {
            return .Error(status: 500, message:"can not get github access token")
        }
        guard let githubUser = try getGithubUser(accessToken) else {
            return .Error(status: 500, message:"can not get github user")
        }
        
        try loign(socialUser: githubUser, provider: .Github)
        return .Redirect(url: "/user/mypage")
    }
    
    private func loign(socialUser socialUser: SocialUser, provider: UserProvider) throws {
        //  check if already stored provider user id in user table
        if let userEntity = try userRepository.findByProviderId(socialUser.id, provider: provider), userId = userEntity.id {
            //  update user data
            let userEntity = UserEntity(id: userId, provider: provider, providerUserId: socialUser.id, providerUserName: socialUser.name)
            try userRepository.update(userEntity)
            
            //  login
            session["id"] = userId
        } else {
            //  store provider user id into user table
            let userEntity = UserEntity(id: nil, provider: provider, providerUserId: socialUser.id, providerUserName: socialUser.name)
            try userRepository.insert(userEntity)
            
            //  login
            let userId = userRepository.lastInsertId()
            session["id"] = userId
        }
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
        
        guard let jsonMap = jsonObject as? [String: Any] else { return nil }
        guard let accessToken = jsonMap["access_token"] as? String else { return nil }
        return accessToken
    }
    
    private func getGithubUser(accessToken: String) throws -> SocialUser? {
        let url = "https://api.github.com/user?access_token=\(accessToken)"
        /*
        response example
        {"login":"user name","id":1}
        */
        guard let jsonObject = try curl(url, header: "User-Agent: Awesome-Octocat-App") else { return nil }
        guard let jsonMap = jsonObject as? [String: Any] else { return nil }
        guard let id = jsonMap["id"] as? Int else { return nil }
        guard let name = jsonMap["login"] as? String else { return nil }
        return (id: String(id), name: name)
    }
    
    private func curl(url: String, header: String? = nil, postParams: [String: String]? = nil) throws -> JSONConvertible? {
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
