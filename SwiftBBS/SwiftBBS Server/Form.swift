//
//  Form.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/05.
//	Copyright GrooveLab
//

import PerfectLib

struct FormError : ErrorType {
    var errorMessages: [String: String]
    
    func toString() -> String {
        var message = ""
        for (key, value) in errorMessages {
            message += key + ":" + value + ". "
        }
        return message
    }
}

class Form {
    var validatorSetting: [String: [String]]  {
        return [:]
    }
    var validatorManager: ValidatorManager {
        return ValidatorManager.generate(validatorSetting)
    }
    var validatedValues = [String: Any]()
    
    func validate(request: WebRequest) throws {
        var errorMessages = [String: String]()
        
        try validatorSetting.forEach { (key, _) -> () in
            do {
                let validators = validatorManager.validators(key)
                if validators.filter( {$0 is IntValidator} ).count > 0 {
                    validatedValues[key] = try validatorManager.validatedInt(key, value: request.param(key))
                } else if validators.filter( {$0 is UploadImageValidator} ).count > 0 {
                    validatedValues[key] = try validatorManager.validatedFile(key, value: request.uploadedFile(key))
                } else {
                    validatedValues[key] = try validatorManager.validatedString(key, value: request.param(key))
                }
                
                if validators.filter( {$0 is RequiredValidator} ).count > 0 {
                    validatedValues[key] = validatedValues[key]!
                }
            } catch ValidationError.Invalid(let errorMessage) {
                errorMessages[key] = errorMessage
            }
        }
        
        if errorMessages.count > 0 {
            throw FormError(errorMessages: errorMessages)
        }
    }
}
