//
//  extension.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/16.
//	Copyright GrooveLab
//
//

import PerfectLib

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
        let encoded = try JSONEncode().encode(values)
        appendBodyString(encoded)
    }
}

extension WebRequest {
    var action: String {
        return urlVariables["action"] ?? "index"
    }
    var acceptJson: Bool {
        return httpAccept().contains("application/json")
    }
}

extension String {
    var htmlBrString: String {
        return stringByReplacingString("\r\n", withString: "\n").stringByReplacingString("\n", withString: "<br>")
    }
    
    //  if function in PerfectLib was changed to pulic, remove this
    func stringByReplacingString(find: String, withString: String) -> String {
        
        guard !find.isEmpty else {
            return self
        }
        guard !self.isEmpty else {
            return self
        }
        
        var ret = ""
        var idx = self.startIndex
        let endIdx = self.endIndex
        
        while idx != endIdx {
            if self[idx] == find[find.startIndex] {
                var newIdx = idx.advancedBy(1)
                var findIdx = find.startIndex.advancedBy(1)
                let findEndIdx = find.endIndex
                
                while newIdx != endIndex && findIdx != findEndIdx && self[newIdx] == find[findIdx] {
                    newIdx = newIdx.advancedBy(1)
                    findIdx = findIdx.advancedBy(1)
                }
                
                if findIdx == findEndIdx { // match
                    ret.appendContentsOf(withString)
                    idx = newIdx
                    continue
                }
            }
            ret.append(self[idx])
            idx = idx.advancedBy(1)
        }
        
        return ret
    }
}
