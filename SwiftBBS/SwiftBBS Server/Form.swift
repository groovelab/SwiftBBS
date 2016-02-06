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
    func updateProperty(key: String, value: String)
    func updateProperty(key: String, value: Int)
    func updateProperty(key: String, value: MimeReader.BodySpec)
}

extension FormType {
    func validate(request: WebRequest) throws {
        let validatorManager = ValidatorManager.generate(fromStringKeyAndValidators: validatorSetting)
        var errorMessages = [String: String]()
        
        try validatorSetting.forEach { (key, _) in
            do {
                var validatedValue: Any?
                let validators = validatorManager.validators(key)
                
                if validators.filter( {$0 is IntValidator} ).count > 0 {
                    validatedValue = try validatorManager.validatedInt(key, value: request.param(key))
                } else if validators.filter( {$0 is UploadImageValidator} ).count > 0 {
                    validatedValue = try validatorManager.validatedFile(key, value: request.uploadedFile(key))
                } else {
                    validatedValue = try validatorManager.validatedString(key, value: request.param(key))
                }

                switch validatedValue {
                case let value as String:
                    updateProperty(key, value: value)
                case let value as Int:
                    updateProperty(key, value: value)
                case let value as MimeReader.BodySpec:
                    updateProperty(key, value: value)
                default: break
                }
            } catch ValidationError.Invalid(let errorMessage) {
                errorMessages[key] = errorMessage
            }
        }
        
        if errorMessages.count > 0 {
            throw FormError(messages: errorMessages)
        }
    }
    
    //  implement if need
    func updateProperty(key: String, value: String) {}
    func updateProperty(key: String, value: Int) {}
    func updateProperty(key: String, value: MimeReader.BodySpec) {}
}
