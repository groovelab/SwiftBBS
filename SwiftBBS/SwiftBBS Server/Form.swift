//
//  Form.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/05.
//  Copyright GrooveLab
//

import PerfectLib

protocol FormType {
    var validationRules: ValidatorManager.ValidationKeyAndRules { get }
    subscript (key: String) -> Any? { get set }
}

extension FormType {
    mutating func validate(request: WebRequest) throws {
        let validatorManager = ValidatorManager.generate(fromValidationKeyAndRules: validationRules)
        var errorMessages = [String: String]()
        
        try validationRules.forEach { (key, _) in
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
            } catch let ValidationError.Invalid(errorMessage) {
                errorMessages[key] = errorMessage
            }
        }
        
        if errorMessages.count > 0 {
            throw FormError(messages: errorMessages)
        }
    }
}

//class ExampleForm : FormType {
//    var comment: String!
//
//    var validationRules: ValidatorManager.ValidationKeyAndRules {
//        return [
//            "comment": [
//                ValidationType.Required,
//                ValidationType.Length(min: 1, max: 1000)
//            ],
//        ]
//    }
//    
//    subscript (key: String) -> Any? {
//        get { return nil } //  not use
//        set {
//            switch key {
//            case "comment": comment = newValue! as! String
//            default: break
//            }
//        }
//    }
//}
