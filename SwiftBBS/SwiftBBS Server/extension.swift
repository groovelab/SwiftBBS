//
//  extension.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//  Copyright GrooveLab
//

import OpenSSL
import MySQL
import PerfectLib

extension WebRequest {
    var action: String {
        return urlVariables["action"] ?? "index"
    }
    var acceptJson: Bool {
        return httpAccept().contains("application/json")
    }
    var docRoot: String {
        return documentRoot.addedLastSlashString
    }
    
    func uploadedFile(fieldName: String) -> MimeReader.BodySpec? {
        return fileUploads.filter { $0.fieldName == fieldName }.first
    }
}

extension WebResponse {
    func render(templatePath: String, values: MustacheEvaluationContext.MapType) throws -> String {
        let fullPath = "Templates/" + templatePath
        let file = File(fullPath)
        
        try file.openRead()
        defer { file.close() }
        let bytes = try file.readSomeBytes(file.size())
        
        let parser = MustacheParser()
        let str = UTF8Encoding.encode(bytes)
        let template = try parser.parse(str)
        
        let context = MustacheEvaluationContext(map: values)
        context.filePath = file.path()
        let collector = MustacheEvaluationOutputCollector()
        try template.evaluatePragmas(context, collector: collector, requireHandler: false)
        template.evaluate(context, collector: collector)
        return collector.asString()
    }
    
    func renderHTML(templatePath: String, values: MustacheEvaluationContext.MapType) throws {
        let responsBody = try render(templatePath, values: values)
        appendBodyString(responsBody)
        addHeader("Content-type", value: "text/html")
    }
    
    func outputJson(values: [String:JSONValue]) throws {
        addHeader("content-type", value: "application/json")
        let encoded = try values.jsonEncodedString()
        appendBodyString(encoded)
    }
}

extension String {
    var isEmpty: Bool {
        return characters.count == 0
    }
    
    var htmlBrString: String {
        return stringByReplacingString("\r\n", withString: "\n").stringByReplacingString("\n", withString: "<br>")
    }
    
    var sha1: String {
        return String.base64encode(utf8.sha1)
    }
    
    var addedLastSlashString: String {
        return self + (((String(characters.last) ?? "") == "/") ? "" : "/")
    }
    
    var fileExtension: String? {
        return lowercaseString.componentsSeparatedByString(".").last
    }
    
    func base64encode() -> String {
        let bytes = UTF8Encoding.decode(self)
        return self.dynamicType.base64encode(bytes)
    }

    func base64decode() -> String {
        var padding = 0
        if hasSuffix("==") {
            padding = 2
        } else if hasSuffix("=") {
            padding = 1
        }
        let decodedLength = characters.count * 3 / 4 - padding

        let base64Bytes = UTF8Encoding.decode(self)
        let bio = BIO_push(BIO_new(BIO_f_base64()), BIO_new_mem_buf(UnsafeMutablePointer<UInt8>(base64Bytes), -1));
        defer { BIO_free_all(bio) }
        
        BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL)
        let bytes = UnsafeMutablePointer<UInt8>.alloc(decodedLength + 1)
        defer { bytes.destroy() ; bytes.dealloc(decodedLength + 1) }
        
        print(BIO_read(bio, bytes, Int32(characters.count)))
        
        guard Int32(decodedLength) == BIO_read(bio, bytes, Int32(characters.count)) else { return "" }
        return UTF8Encoding.encode(GenerateFromPointer(from: bytes, count: decodedLength))
    }
    
    static func isEmpty(string: String?) -> Bool {
        guard let string = string else { return false }
        return string.isEmpty
    }
    
    static func randomString(length: Int, includeSymbol: Bool = false) -> String {
        let sourceString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" + (includeSymbol ? "!#$%&/" : "")
        let sourceChars = [Character](sourceString.characters)
        
        var chars = [Character]()
        for _ in 0..<length {
            chars.append(sourceChars[random() % sourceChars.count])
        }

        return String(chars)
    }
    
    static func base64encode(bytes: [UInt8]) -> String {
        let bio = BIO_push(BIO_new(BIO_f_base64()), BIO_new(BIO_s_mem()))
        
        BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL)
        BIO_write(bio, bytes, Int32(bytes.count))
        BIO_ctrl(bio, BIO_CTRL_FLUSH, 0, nil)
        
        var mem = UnsafeMutablePointer<BUF_MEM>()
        BIO_ctrl(bio, BIO_C_GET_BUF_MEM_PTR, 0, &mem)
        BIO_ctrl(bio, BIO_CTRL_SET_CLOSE, Int(BIO_NOCLOSE), nil)
        BIO_free_all(bio)
        
        let txt = UnsafeMutablePointer<UInt8>(mem.memory.data)
        let ret = UTF8Encoding.encode(GenerateFromPointer(from: txt, count: mem.memory.length))
        free(mem.memory.data)
        return ret
    }
}

extension String.UTF8View {
    var sha1: [UInt8] {
        let bytes = UnsafeMutablePointer<UInt8>.alloc(Int(SHA_DIGEST_LENGTH))
        defer { bytes.destroy() ; bytes.dealloc(Int(SHA_DIGEST_LENGTH)) }
        
        SHA1(Array<UInt8>(self), (self.count), bytes)

        var r = [UInt8]()
        for idx in 0..<Int(SHA_DIGEST_LENGTH) {
            r.append(bytes[idx])
        }
        return r
    }
}

extension MySQLStmt {
    func bindParam(param: UInt) {
        bindParam(UInt64(param))
    }

    func bindParams(params: [Any]?) {
        guard let params = params else { return }
        params.forEach({ param in
            if let param = param as? Int {
                bindParam(param)
            } else if let param = param as? UInt {
                bindParam(param)
            } else if let param = param as? String {
                bindParam(param)
            }
        })
    }
}

extension MySQLStmt : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(errorCode()): \(errorMessage())"
    }
}
