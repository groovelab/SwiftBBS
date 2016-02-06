//
//  FormError.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//	Copyright GrooveLab
//

struct FormError : ErrorType, CustomStringConvertible {
    var messages: [String: String]
    var description: String {
        var message = ""
        for (key, value) in messages {
            message += key + ":" + value + ". "
        }
        return message
    }
}

