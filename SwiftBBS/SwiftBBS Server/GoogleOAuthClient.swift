//
//  GoogleOAuthClient.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/17.
//  Copyright GrooveLab
//

final class GoogleOAuthClient : OAuthClient {
    let clientId: String
    let clientSecret: String
    let state: String = String.randomString(10)
    
    required init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    func authUrl(redirectUri: String) -> String {
        return "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&response_type=code&scope=profile&redirect_uri=\(redirectUri)&state=\(state)"
    }
    
    func getAccessToken(code: String, extraData: String) throws -> String {
        let url = "https://www.googleapis.com/oauth2/v4/token"
        /*
        response example
        success : {"access_token": "hoge","token_type": "bearer", "expires_in":	1234, "id_token": "hoge"}
        error   : {"error": "error_message", "error_description": "Bad Request"}
        */
        guard let jsonObject = try request(url, headers: nil, postParams: [
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": extraData,
            "grant_type": "authorization_code"
            ]) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let accessToken = jsonMap["access_token"] as? String else { throw OAuthClientError.Fail("accessToken") }
        return accessToken
    }
    
    func getSocialUser(accessToken: String) throws -> OAuthSocialUser {
        let url = "https://www.googleapis.com/plus/v1/people/me?access_token=\(accessToken)"
        /*
        response example
        {"displayName":"user name", "id":"1"}
        */
        guard let jsonObject = try request(url) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let id = jsonMap["id"] as? String else { throw OAuthClientError.Fail("id") }
        guard let name = jsonMap["displayName"] as? String else { throw OAuthClientError.Fail("name") }
        return (id: id, name: name)
    }
}
