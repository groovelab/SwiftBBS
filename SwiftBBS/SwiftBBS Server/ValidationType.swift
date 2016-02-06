//
//  ValidationType.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//	Copyright GrooveLab
//

protocol ValidationTypeCompatible {
    func toStringRule() -> String
}

extension String : ValidationTypeCompatible {
    func toStringRule() -> String {
        return self
    }
}

enum ValidationType : ValidationTypeCompatible {
    case Required
    case Length(min: Int?, max: Int?)
    case Integer(min: Int?, max: Int?)
    case Identical(targetKey: String)
    case Image(fileSize: Int?, fileExtensions: [String])
    
    func toStringRule() -> String {
        switch self {
        case .Required:
            return "required"
        case .Length(let min, let max):
            return "length," + (String(min) ?? "n") + "," + (String(max) ?? "n")
        case .Integer(let min, let max):
            return "int," + (String(min) ?? "n") + "," + (String(max) ?? "n")
        case .Identical(let targetKey):
            return "identical,\(targetKey)"
        case .Image(let fileSize, let fileExtensions):
            var stringRule = "image," + (String(fileSize) ?? "n")
            fileExtensions.forEach { ext in
                stringRule += "," + ext
            }
            return stringRule
        }
    }
}
