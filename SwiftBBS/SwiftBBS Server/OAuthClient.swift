//
//  OAuthClient.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/17.
//  Copyright GrooveLab
//

import PerfectLib

enum OAuthClientError : ErrorType {
    case Fail(String)
}

typealias OAuthSocialUser = (id: String, name: String)

protocol OAuthClient : class {
    var clientId: String { get }
    var clientSecret: String { get }
    var state: String { get }

    init(clientId: String, clientSecret: String)

    func authUrl(redirectUri: String) -> String
    func getAccessToken(code: String, extraData: String) throws -> String
    func getSocialUser(accessToken: String) throws -> OAuthSocialUser
}

extension OAuthClient {
    func getSocialUser(code code: String, extraData: String = "") throws -> OAuthSocialUser {
        let accessToken = try getAccessToken(code, extraData: extraData)
        return try getSocialUser(accessToken)
    }

    func request(url: String, headers: [String: String]? = nil, postParams: [String: String]? = nil) throws -> JSONConvertible? {
        let httpClient = HttpClient(url: url)
        return try httpClient.requestSynchronousJSON(headers, postParams: postParams)
    }
}
