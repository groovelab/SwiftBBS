//
//  RequiredValidator.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//	Copyright GrooveLab
//

class RequiredValidator : Validator {
    var errorMessage = "required"
    
    func validate(value: Any?) throws {
        guard let value = value else {
            throw ValidationError.Invalid(errorMessage)
        }
        
        if let string = value as? String where string.characters.count == 0 {
            throw ValidationError.Invalid(errorMessage)
        }
    }
}
