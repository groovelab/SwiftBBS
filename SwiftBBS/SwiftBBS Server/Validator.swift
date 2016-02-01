//
//  Validator.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/02.
//	Copyright GrooveLab
//

import PerfectLib

enum ValidationError : ErrorType {
    case Invalid(String)
    case Fail
}

protocol Validator {
    func validate(value: Any?) throws
}

class ValidatorManager : Validator {
    typealias RuleAndArgs = (rule: String, args: [String])
    
    var validators = [Validator]()
    
    static func build(stringValidators: [String]) -> ValidatorManager {
        let validatorManager = ValidatorManager()
        validatorManager.addValidators(fromStrings: stringValidators)
        return validatorManager
    }
    
    func addValidators(fromStrings stringValidators: [String]) {
        for stringValidator in stringValidators {
            let rulesAndArgs = ruleAndArgs(stringValidator)
            let rule = rulesAndArgs.rule
            let args = rulesAndArgs.args
            
            switch rule {
            case "required":
                validators.append(RequiredValidator())
            case "length":
                if args.count == 2, let min = Int(args[0]), let max = Int(args[1]) {
                    validators.append(LengthValidator(min: min, max: max))
                } else {
                    validators.append(LengthValidator())
                }
            case "int":
                if args.count == 2 {
                    if let min = Int(args[0]), let max = Int(args[1]) {
                        validators.append(IntValidator(min: min, max: max))
                    } else if let min = Int(args[0]) {
                        validators.append(IntValidator(min: min))
                    } else if let max = Int(args[1]) {
                        validators.append(IntValidator(max: max))
                    } else {
                        validators.append(IntValidator())
                    }
                } else {
                    validators.append(IntValidator())
                }
            case "image":
                let validator = UploadImageValidator()
                if args.count > 0, let fileSize = Int(args[0]) {
                    validator.fileSize = fileSize
                }
                if args.count > 1 {
                    args.dropFirst().forEach { validator.addAllowExtension($0) }
                }
                validators.append(validator)
            default: break
            }
        }
    }
    
    func validate(value: Any?) throws {
        try validators.forEach { (validator) in
            try validator.validate(value)
        }
    }
    
    func validatedString(value: Any?) throws -> String {
        try validate(value)
        
        guard let validatedString = value as? String else {
            throw ValidationError.Fail
        }
        return validatedString
    }
    
    func validatedInt(value: Any?) throws -> Int {
        try validate(value)
        
        guard let validatedInt = Int(value as? String ?? "") else {
            throw ValidationError.Fail
        }
        return validatedInt
    }
    
    private func ruleAndArgs(ruleAndArgsString: String) -> RuleAndArgs {
        guard ruleAndArgsString.contains(",") else {
            return (rule: ruleAndArgsString, args: [String]())
        }
        
//        let splitedString = ruleAndArgsString.characters.split(",")
//        let rule = String(splitedString[0])
//        let args = splitedString.dropFirst().map { (arg) -> String in
//            return String(arg)
//        }

        let separatedString = ruleAndArgsString.componentsSeparatedByString(",")
        let rule = separatedString.first!
        let args = Array(separatedString.dropFirst())
        
        return (rule: rule, args: args)
    }
}

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
    
    convenience init(min: Int, max: Int) {
        self.init()
        self.min = min
        self.max = max
    }
    
    convenience init(min: Int) {
        self.init()
        self.min = min
    }
    
    convenience init(max: Int) {
        self.init()
        self.max = max
    }
    
    func validate(value: Any?) throws {
        guard let value = value else {
            return
        }
        guard let stringValue = value as? String else {
            throw ValidationError.Invalid(errorMessage)
        }
        
        if let min = min where stringValue.characters.count < min {
            throw ValidationError.Invalid(errorMessageShorter)
        } else if let max = max where stringValue.characters.count > max {
            throw ValidationError.Invalid(errorMessageLonger)
        }
    }
}

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
    
    convenience init(min: Int, max: Int) {
        self.init()
        self.min = min
        self.max = max
    }
    
    convenience init(min: Int) {
        self.init()
        self.min = min
    }
    
    convenience init(max: Int) {
        self.init()
        self.max = max
    }
    
    func validate(value: Any?) throws {
        guard let value = value else {
            return
        }
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

class UploadFileValidator : Validator {
    var fileSize: Int? = 10 * 1024 * 1024  //  10 MB
    var fileExtensions = [String]()
    var contentTypes = [String]()
    
    var errorMessageFileSize: String {
        return "maximum file size is \(fileSize!) byte"
    }
    var errorMessageFileExtension: String {
        return "allowed file extensions are \(fileExtensions.description)"
    }
    var errorMessageContentType: String {
        return "allowed content types are \(contentTypes.description)"
    }
    
    func validate(value: Any?) throws {
        guard let value = value as? MimeReader.BodySpec else {
            return
        }
        
        if let fileSize = fileSize where fileSize < value.fileSize {
            throw ValidationError.Invalid(errorMessageFileSize)
        } else if fileExtensions.count > 0 && !fileExtensions.contains(value.fileName.fileExtension ?? "") {
            throw ValidationError.Invalid(errorMessageFileExtension)
        } else if contentTypes.count > 0 && !contentTypes.contains(value.contentType) {
            throw ValidationError.Invalid(errorMessageContentType)
        }
    }
}

class UploadImageValidator : UploadFileValidator {
    func addAllowExtension(fileExtension: String) {
        switch fileExtension {
        case "jpg":
            fileExtensions.append("jpg")
            fileExtensions.append("jpeg")
            contentTypes.append("image/jpeg")
        default:
            fileExtensions.append(fileExtension)
            contentTypes.append("image/\(fileExtension)")
        }
    }
}
