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
    var validatorSetting: ValidatorManager.ValidatorsSetting { get }
    subscript (key: String) -> Any? { get set }
}

extension FormType {
    mutating func validate(request: WebRequest) throws {
        let validatorManager = ValidatorManager.generate(fromStringKeyAndValidators: validatorSetting)
        var errorMessages = [String: String]()
        
        try validatorSetting.forEach { (key, _) in
            do {
                let validators = validatorManager.validators(key)
                
                //  for identical validator
                validators.filter( {$0 is IdenticalValidator} ).forEach({ validator in
                    if let validator = validator as? IdenticalValidator {
                        validator.targetValue = request.param(validator.targetKey)
                    }
                })
                
                if validators.filter( {$0 is IntValidator} ).count > 0 {
                    self[key] = try validatorManager.validatedInt(key, value: request.param(key))
                } else if validators.filter( {$0 is UploadImageValidator} ).count > 0 {
                    self[key] = try validatorManager.validatedFile(key, value: request.uploadedFile(key))
                } else {
                    self[key] = try validatorManager.validatedString(key, value: request.param(key))
                }
            } catch ValidationError.Invalid(let errorMessage) {
                errorMessages[key] = errorMessage
            }
        }
        
        if errorMessages.count > 0 {
            throw FormError(messages: errorMessages)
        }
    }
}
