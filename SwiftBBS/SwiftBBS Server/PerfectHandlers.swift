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
        
        var count = session.getVar("count", defaultValue: 0);
        print("count : " + String(count))
        session["count"] = ++count
        
        response.appendBodyString("Session handler: count is \(count)")
        response.requestCompletedCallback()
    }
}