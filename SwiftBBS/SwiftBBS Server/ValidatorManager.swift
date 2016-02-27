//
//  ValidatorManager.swift
//  SwiftBBS
//
//  Created by 難波健雄 on 2016/02/07.
//
//

class ValidatorManager {
    typealias RuleAndArgs = (rule: String, args: [String])
    typealias ValidationKeyAndRules = [String: [ValidationTypeCompatible]]
    
    private var validatorContainer = [String: [Validator]]()
    
    static func generate(fromValidationKeyAndRules validationKeyAndRules: ValidationKeyAndRules) -> ValidatorManager {
        let validatorManager = ValidatorManager()
        
        validationKeyAndRules.forEach { key, rules in
            var stringRules = [String]()
            rules.forEach({ rule in
                //  ex.) rule is "required" or ValidationType.Required
                stringRules.append(rule.toStringRule())
            })
            validatorManager.addValidators(key, stringRules: stringRules)
        }
        
        return validatorManager
    }
    
    func addValidators(key: String, stringRules: [String]) {
        for stringRule in stringRules {
            let rulesAndArgs = ruleAndArgs(stringRule)
            let rule = rulesAndArgs.rule
            let args = rulesAndArgs.args
            
            var validators = [Validator]()
            if let validatorList = validatorContainer[key] {
                validators = validatorList
            }
            
            switch rule {
            case "required":
                validators.append(RequiredValidator())
            case "length":
                let validator = LengthValidator()
                if args.count > 0, let min = Int(args[0]) {
                    validator.min = min
                }
                if args.count > 1, let max = Int(args[1]) {
                    validator.max = max
                }
                validators.append(validator)
            case "int":
                let validator = IntValidator()
                if args.count > 0, let min = Int(args[0]) {
                    validator.min = min
                }
                if args.count > 1, let max = Int(args[1]) {
                    validator.max = max
                }
                validators.append(validator)
            case "uint":
                let validator = UIntValidator()
                if args.count > 0, let min = UInt(args[0]) {
                    validator.min = min
                }
                if args.count > 1, let max = UInt(args[1]) {
                    validator.max = max
                }
                validators.append(validator)
            case "identical":
                if args.count == 1 {
                    validators.append(IdenticalValidator(targetKey: args[0]))
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
            
            validatorContainer[key] = validators
        }
    }
    
    func validate(key: String, value: Any?) throws {
        guard let validators = validatorContainer[key] else {
            throw ValidationError.Fail
        }
        try validators.forEach { (validator) in
            try validator.validate(value)
        }
    }
    
    func validatedString(key: String, value: Any?) throws -> String? {
        try validate(key, value: value)
        
        if value == nil {
            return nil
        }
        guard let validatedString = value as? String else {
            throw ValidationError.Fail
        }
        return validatedString
    }
    
    func validatedInt(key: String, value: Any?) throws -> Int? {
        try validate(key, value: value)
        
        if value == nil {
            return nil
        }
        guard let validatedInt = Int(value as? String ?? "") else {
            throw ValidationError.Fail
        }
        return validatedInt
    }
    
    func validatedUInt(key: String, value: Any?) throws -> UInt? {
        try validate(key, value: value)
        
        if value == nil {
            return nil
        }
        guard let validatedUInt = UInt(value as? String ?? "") else {
            throw ValidationError.Fail
        }
        return validatedUInt
    }
    
    func validatedFile(key: String, value: Any?) throws -> UploadFileValidator.UploadedFileType? {
        try validate(key, value: value)
        
        if value == nil {
            return nil
        }
        guard let validatedFile = value as? UploadFileValidator.UploadedFileType else {
            throw ValidationError.Fail
        }
        return validatedFile
    }
    
    func validators(key: String) -> [Validator] {
        if let validators = validatorContainer[key] {
            return validators
        } else {
            return [Validator]()
        }
    }
    
    private func ruleAndArgs(ruleAndArgsString: String) -> RuleAndArgs {
        guard ruleAndArgsString.contains(",") else {
            return (rule: ruleAndArgsString, args: [String]())
        }
        
        let separatedString = ruleAndArgsString.componentsSeparatedByString(",")
        let rule = separatedString.first!
        let args = Array(separatedString.dropFirst())
        
        return (rule: rule, args: args)
    }
}
