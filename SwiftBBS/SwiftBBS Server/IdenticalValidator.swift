//
//  File.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//  Copyright GrooveLab
//

class IdenticalValidator : Validator {
    var targetKey: String
    var targetValue: String?
    
    var errorMessage: String {
        return "not match with \(targetKey)"
    }
    
    init(targetKey: String) {
        self.targetKey = targetKey
    }
    
    func validate(value: Any?) throws {
        guard let value = value as? String else { return }
        guard let targetValue = targetValue else {
            throw ValidationError.Fail
        }
        
        if value != targetValue {
            throw ValidationError.Invalid(errorMessage)
        }
    }
}
