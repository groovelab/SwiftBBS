//
//  IntValidator.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//  Copyright GrooveLab
//

class IntValidator : Validator {
    var min: Int?
    var max: Int?
    
    var errorMessage = "not int"
    var errorMessageLess: String {
        return "min is \(min!)"
    }
    var errorMessageGreater: String {
        return "max is \(max!)"
    }
    
    func validate(value: Any?) throws {
        guard let value = value else { return }
        guard let intValue = Int(value as? String ?? "") else {
            throw ValidationError.Invalid(errorMessage)
        }
        
        if let min = min where intValue < min {
            throw ValidationError.Invalid(errorMessageLess)
        } else if let max = max where intValue > max {
            throw ValidationError.Invalid(errorMessageGreater)
        }
    }
}
