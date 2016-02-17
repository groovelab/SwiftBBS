//
//  ValidationError.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//  Copyright GrooveLab
//

enum ValidationError : ErrorType {
    case Invalid(String)
    case Fail
}
