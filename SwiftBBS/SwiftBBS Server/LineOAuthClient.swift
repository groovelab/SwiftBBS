//
//  GithubOAuthClient.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/04/09.
//  Copyright GrooveLab
//

final class LineOAuthClient : OAuthClient {
    let clientId: String
    let clientSecret: String
    let state: String = String.randomString(10)
    
    required init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    func authUrl(redirectUri: String) -> String {
        return "https://access.line.me/dialog/oauth/weblogin?response_type=code&client_id=\(clientId)&redirect_uri=\(redirectUri)&state=\(state)"
    }
    
    func getAccessToken(code: String, extraData: String = "") throws -> String {
        let url = "https://api.line.me/v1/oauth/accessToken"
        /*
         response example
         success : {"access_token":"hoge","token_type":"bearer","scope":""}
         error   : {"error":"bad_verification_code","error_description":"The code passed is incorrect or expired.","error_uri":"https://developer.github.com/v3/oauth/#bad-verification-code"}
         */
        guard let jsonObject = try request(url, headers: ["Content-Type": "application/x-www-form-urlencoded"], postParams: [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": extraData
            ]) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let accessToken = jsonMap["access_token"] as? String else { throw OAuthClientError.Fail("accessToken") }
        return accessToken
    }
    
    func getSocialUser(accessToken: String) throws -> OAuthSocialUser {
        let url = "https://api.line.me//v1/profile"
        /*
         response example
         {"login":"user name","id":1}
         */
        guard let jsonObject = try request(url, headers: ["Authorization": "Bearer \(accessToken)"]) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let id = jsonMap["mid"] as? String else { throw OAuthClientError.Fail("id")}
        guard let name = jsonMap["displayName"] as? String else { throw OAuthClientError.Fail("name") }
        return (id: id, name: name)
    }
}
