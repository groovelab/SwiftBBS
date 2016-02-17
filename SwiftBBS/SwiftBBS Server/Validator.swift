//
//  Validator.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/02.
//  Copyright GrooveLab
//

protocol Validator {
    func validate(value: Any?) throws
}