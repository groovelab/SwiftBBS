//
//  Form.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/05.
//	Copyright GrooveLab
//

import PerfectLib

struct FormError : ErrorType {
    var messages: [String: String]
    
    func toString() -> String {
        var message = ""
        for (key, value) in messages {
            message += key + ":" + value + ". "
        }
        return message
    }
}

protocol FormType {
    var validatorSetting: [String: [String]] { get }
}

extension FormType {
    var validatorManager: ValidatorManager {
        return ValidatorManager(stringKeyAndValidators: validatorSetting)
    }
    
    func validate(request: WebRequest) throws -> [String: Any] {
        var errorMessages = [String: String]()
        var validatedValues = [String: Any]()

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
            throw FormError(messages: errorMessages)
        }
        
        return validatedValues
    }
}
