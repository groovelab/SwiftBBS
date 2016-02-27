//
//  AuthHandler.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/08.
//  Copyright GrooveLab
//

import PerfectLib
import cURL

import Foundation

class OAuthHandler : BaseRequestHandler {
    private let OAuthStateSessionKey = "oauth_state"
    
    private lazy var googleOAuthClient: GoogleOAuthClient = GoogleOAuthClient(clientId: Config.googleClientId, clientSecret: Config.googleClientSecret)
    private lazy var googleRedirectUri: String = self.request.isHttps() ? "https" : "http" + "://\(self.request.httpHost())/oauth/google_callback"
    
    private lazy var facebookOAuthClient: FacebookOAuthClient = FacebookOAuthClient(clientId: Config.facebookAppId, clientSecret: Config.facebookAppSecret)
    private lazy var facebookRedirectUri: String = self.request.isHttps() ? "https" : "http" + "://\(self.request.httpHost())/oauth/facebook_callback"
    
    private lazy var githubOAuthClient: GithubOAuthClient = GithubOAuthClient(clientId: Config.gitHubClientId, clientSecret: Config.gitHubClientSecret)
    
    
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
        prepareForOauth(googleOAuthClient.state)
        
        let authUrl = googleOAuthClient.authUrl(googleRedirectUri)
        return .Redirect(url: authUrl)
    }
    
    func googleCallbackAction() throws -> ActionResponse {
        guard let state = request.param("state") else {
            return .Error(status: 500, message:"can not get google state")
        }
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get google code")
        }

        if !validateState(state) {
            return .Error(status: 500, message:"invalid google state")
        }
        
        do {
            let socialUser = try googleOAuthClient.getSocialUser(code: code, extraData: googleRedirectUri)
            try loign(socialUser: socialUser, provider: .Google)
            return .Redirect(url: "/user/mypage")
        } catch OAuthClientError.Fail(let message) {
            return .Error(status: 500, message: message)
        }
    }
    
    func facebookAction() throws -> ActionResponse {
        prepareForOauth(facebookOAuthClient.state)
        
        let authUrl = facebookOAuthClient.authUrl(facebookRedirectUri)
        return .Redirect(url: authUrl)
    }
    
    func facebookCallbackAction() throws -> ActionResponse {
        guard let state = request.param("state") else {
            return .Error(status: 500, message:"can not get google state")
        }
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get google code")
        }

        if !validateState(state) {
            return .Error(status: 500, message:"invalid google state")
        }

        do {
            let socialUser = try facebookOAuthClient.getSocialUser(code: code, extraData: facebookRedirectUri)
            try loign(socialUser: socialUser, provider: .Facebook)
            return .Redirect(url: "/user/mypage")
        } catch OAuthClientError.Fail(let message) {
            return .Error(status: 500, message: message)
        }
    }

    
    func githubAction() throws -> ActionResponse {
        prepareForOauth(githubOAuthClient.state)
        
        let authUrl = githubOAuthClient.authUrl()
        return .Redirect(url: authUrl)
    }
    
    func githubCallbackAction() throws -> ActionResponse {
        guard let state = request.param("state") else {
            return .Error(status: 500, message:"can not get google state")
        }
        guard let code = request.param("code") else {
            return .Error(status: 500, message:"can not get google code")
        }
        
        if !validateState(state) {
            return .Error(status: 500, message:"invalid google state")
        }
        
        do {
            let socialUser = try githubOAuthClient.getSocialUser(code: code)
            try loign(socialUser: socialUser, provider: .Github)
            return .Redirect(url: "/user/mypage")
        } catch OAuthClientError.Fail(let message) {
            return .Error(status: 500, message: message)
        }
    }
    
    //  TODO: create UserService with social login method
    private func loign(socialUser socialUser: OAuthSocialUser, provider: UserProvider) throws {
        //  check if already stored provider user id in user table
        if let userEntity = try userRepository.findByProviderId(socialUser.id, provider: provider), userId = userEntity.id {
            //  update user data
            let userEntity = UserEntity(id: userId, provider: provider, providerUserId: socialUser.id, providerUserName: socialUser.name)
            try userRepository.update(userEntity)
            
            //  login
            session["id"] = String(userId)  //  TODO: create method
        } else {
            //  store provider user id into user table
            let userEntity = UserEntity(id: nil, provider: provider, providerUserId: socialUser.id, providerUserName: socialUser.name)
            let userId = try userRepository.insert(userEntity)
            
            //  login
            session["id"] = String(userId)
        }
    }
    
    private func prepareForOauth(state: String) {
        session[OAuthStateSessionKey] = state
    }
    
    private func validateState(state: String) -> Bool {
        guard let stateInSession = session[OAuthStateSessionKey] as? String else { return false }
        
        session[OAuthStateSessionKey] = nil
        return state == stateInSession
    }
}
