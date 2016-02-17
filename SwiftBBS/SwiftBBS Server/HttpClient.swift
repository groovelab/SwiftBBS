//
//  HttpClient.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/17.
//  Copyright GrooveLab
//

import PerfectLib
import cURL

struct HttpClient {
    let url: String
    let isVerbose: Bool
    
    init(url: String) {
        self.url = url
        self.isVerbose = false
    }
    
    init(url: String, isVerbose: Bool) {
        self.url = url
        self.isVerbose = isVerbose
    }
    
    func requestSynchronousJSON(headers: [String: String]? = nil, postParams: [String: String]? = nil) throws -> JSONConvertible? {
        let curl = CURL(url: url)
        
        if isVerbose {
            curl.setOption(CURLOPT_VERBOSE, int: 1)
        }
        
        if let headers = headers {
            let headerString = headers.map({ key, value in
                return "\(key): \(value)"
            }).joinWithSeparator("; ")
            curl.setOption(CURLOPT_HTTPHEADER, s: headerString)
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
