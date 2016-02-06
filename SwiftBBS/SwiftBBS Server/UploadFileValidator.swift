//
//  UploadFileValidator.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/02/07.
//	Copyright GrooveLab
//

import PerfectLib

class UploadFileValidator : Validator {
    typealias UploadedFileType = MimeReader.BodySpec
    
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
        guard let value = value as? UploadedFileType else { return }
        
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
