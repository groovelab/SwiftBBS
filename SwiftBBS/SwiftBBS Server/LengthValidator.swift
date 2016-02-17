//
//  LengthValidator.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//  Copyright GrooveLab
//

class LengthValidator : Validator {
    var min: Int?
    var max: Int?
    
    var errorMessage = "not string"
    var errorMessageShorter: String {
        return "min length is \(min!)"
    }
    var errorMessageLonger: String {
        return "max length is \(max!)"
    }
    
    func validate(value: Any?) throws {
        guard let value = value else { return }
        guard let stringValue = value as? String else {
            throw ValidationError.Invalid(errorMessage)
        }
        
        if stringValue.isEmpty {
            return
        }
        
        if let min = min where stringValue.characters.count < min {
            throw ValidationError.Invalid(errorMessageShorter)
        } else if let max = max where stringValue.characters.count > max {
            throw ValidationError.Invalid(errorMessageLonger)
        }
    }
}
