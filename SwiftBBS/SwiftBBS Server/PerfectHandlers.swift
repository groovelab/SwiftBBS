//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//	Copyright GrooveLab
//
//

import PerfectLib

public func PerfectServerModuleInit() {
    Routing.Handler.registerGlobally()
    
    //  URL Routing
    Routing.Routes["GET", ["/", "index"] ] = { _ in return IndexHandler() }
    Routing.Routes["GET", ["session"] ] = { _ in return SessionHandler() }
    Routing.Routes["GET", ["template"] ] = { _ in return TemplateHandler() }
    
    print("\(Routing.Routes.description)")
}

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
            let responsBody = try render("template.mustache", values: values)
            response.appendBodyString(responsBody)
        } catch (let e) {
            print(e)
        }
        
        response.requestCompletedCallback()
    }
    
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
}
