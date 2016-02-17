//
//  ValidationType.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//  Copyright GrooveLab
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
        case let .Length(min, max):
            return "length," + (String(min) ?? "n") + "," + (String(max) ?? "n")
        case let .Integer(min, max):
            return "int," + (String(min) ?? "n") + "," + (String(max) ?? "n")
        case let .Identical(targetKey):
            return "identical,\(targetKey)"
        case let .Image(fileSize, fileExtensions):
            var stringRule = "image," + (String(fileSize) ?? "n")
            fileExtensions.forEach { ext in
                stringRule += "," + ext
            }
            return stringRule
        }
    }
}
