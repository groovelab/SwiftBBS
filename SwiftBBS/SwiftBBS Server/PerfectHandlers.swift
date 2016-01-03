//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//	Copyright GrooveLab
//
//

import PerfectLib

//  MARK: - init
public func PerfectServerModuleInit() {
    Routing.Handler.registerGlobally()
    
    //  URL Routing
    Routing.Routes["GET", ["/", "index"] ] = { _ in return IndexHandler() }
    Routing.Routes["GET", ["session"] ] = { _ in return SessionHandler() }
    Routing.Routes["GET", ["template"] ] = { _ in return TemplateHandler() }
    Routing.Routes["POST", ["post"]] = { _ in return PostHandler() }

    print("\(Routing.Routes.description)")
}

//  MARK: - extensions
extension RequestHandler {
    func render(templatePath: String, values: MustacheEvaluationContext.MapType) throws -> String {
        let context = MustacheEvaluationContext(map: values)
        
        let fullPath = "Templates/" + templatePath
        let file = File(fullPath)
        
        try file.openRead()
        defer { file.close() }
        let bytes = try file.readSomeBytes(file.size())
        
        let parser = MustacheParser()
        let str = UTF8Encoding.encode(bytes)
        let template = try parser.parse(str)
        
        let collector = MustacheEvaluationOutputCollector()
        template.evaluate(context, collector: collector)
        return collector.asString()
    }
    
    func renderHTML(templatePath: String, values: MustacheEvaluationContext.MapType, response: WebResponse) throws {
        let responsBody = try render(templatePath, values: values)
        response.appendBodyString(responsBody)
        response.addHeader("Content-type", value: "text/html")
    }
}

extension WebRequest {
    func postParam(targetKey: String) -> String? {
        let keyValues = postParams.filter { (key, value) -> Bool in
            return (targetKey == key)
        }
        
        if keyValues.count == 1 {
            let keyValue = keyValues[0]
            return keyValue.1
        } else {
            return nil
        }
    }
}

//  MARK: - handlers
class IndexHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        //  session
        let session = response.getSession(Config.sessionName)
        print(session.getConfiguration())
        
        response.appendBodyString("Index handler: You accessed path \(request.requestURI())")
        response.requestCompletedCallback()
    }
}

//  use SessionManager
class SessionHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        let session = response.getSession(Config.sessionName)
        print(session.getConfiguration())
        
        var count = session.getVar("count", defaultValue: 0)
        count += 1
        print("count : " + String(count))
        session["count"] = count
        
        response.appendBodyString("Session handler: count is \(count)")
        response.requestCompletedCallback()
    }
}

//  use Mustache
//  
//  need to deploy template files
//  $ cd (PerfectServer Home Direcgtory)
//  $ ln -s "/home/ubuntu/swift/SwiftBBS/SwiftBBS/SwiftBBS Server/Templates" ./
class TemplateHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["value1"] = "sdfsdf"

        do {
            try renderHTML("template.mustache", values: values, response: response)
        } catch (let e) {
            print(e)
        }

        response.requestCompletedCallback()
    }
}

//  post
class PostHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        if let val2 = request.postParam("val2") {
            print(val2)
        }
        
        response.appendBodyString("posted variables : \(request.postParams)")
        response.requestCompletedCallback()
    }
}
