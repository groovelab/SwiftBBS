//
//  GithubOAuthClient.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/17.
//  Copyright GrooveLab
//

final class GithubOAuthClient : OAuthClient {
    let clientId: String
    let clientSecret: String
    let state: String = String.randomString(10)
    
    required init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    func authUrl(redirectUri: String = "") -> String {
        return "https://github.com/login/oauth/authorize?client_id=\(clientId)&state=\(state)"
    }
    
    func getAccessToken(code: String, extraData: String = "") throws -> String {
        let url = "https://github.com/login/oauth/access_token"
        /*
        response example
        success : {"access_token":"hoge","token_type":"bearer","scope":""}
        error   : {"error":"bad_verification_code","error_description":"The code passed is incorrect or expired.","error_uri":"https://developer.github.com/v3/oauth/#bad-verification-code"}
        */
        guard let jsonObject = try request(url, headers: ["Accept": "application/json"], postParams: [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code
            ]) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let accessToken = jsonMap["access_token"] as? String else { throw OAuthClientError.Fail("accessToken") }
        return accessToken
    }
    
    func getSocialUser(accessToken: String) throws -> OAuthSocialUser {
        let url = "https://api.github.com/user?access_token=\(accessToken)"
        /*
        response example
        {"login":"user name","id":1}
        */
        guard let jsonObject = try request(url, headers: ["User-Agent": "OAuthClient"]) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let id = jsonMap["id"] as? Int else { throw OAuthClientError.Fail("id")}
        guard let name = jsonMap["login"] as? String else { throw OAuthClientError.Fail("name") }
        return (id: String(id), name: name)
    }
}
