//
//  FacebookOAuthClient.swift
//  SwiftBBS
//
//  Created by 難波健雄 on 2016/02/18.
//
//

final class FacebookOAuthClient : OAuthClient {
    let clientId: String
    let clientSecret: String
    let state: String = String.randomString(10)
    
    required init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    func authUrl(redirectUri: String) -> String {
        return "https://www.facebook.com/dialog/oauth?client_id=\(clientId)&redirect_uri=\(redirectUri)&state=\(state)"
    }
    
    func getAccessToken(code: String, extraData: String) throws -> String {
        let url = "https://graph.facebook.com/v2.3/oauth/access_token?client_id=\(clientId)&redirect_uri=\(extraData)&client_secret=\(clientSecret)&code=\(code)"
        /*
        response example
        success : {"access_token": "hoge","token_type": "bearer", "expires_in":	1234}
        error   : {"error": {"code": "1", "message": "error message", "fbtrae_id": "", "type": "OAuthException"}}
        */
        guard let jsonObject = try request(url) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let accessToken = jsonMap["access_token"] as? String else { throw OAuthClientError.Fail("accessToken") }
        return accessToken
    }
    
    func getSocialUser(accessToken: String) throws -> OAuthSocialUser {
        let url = "https://graph.facebook.com//v2.5/me?access_token=\(accessToken)"
        /*
        response example
        {"login":"user name","id":1}
        */
        guard let jsonObject = try request(url) else { throw OAuthClientError.Fail("jsonObject") }
        guard let jsonMap = jsonObject as? [String: Any] else { throw OAuthClientError.Fail("jsonMap") }
        guard let id = jsonMap["id"] as? String else { throw OAuthClientError.Fail("id") }
        guard let name = jsonMap["name"] as? String else { throw OAuthClientError.Fail("name") }
        return (id: id, name: name)
    }
}
