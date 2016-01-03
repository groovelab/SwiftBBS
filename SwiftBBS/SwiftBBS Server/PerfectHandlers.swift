//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//	Copyright GrooveLab
//
//

import PerfectLib

let DB_PATH = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + Config.dbName

//  MARK: - init
public func PerfectServerModuleInit() {
    Routing.Handler.registerGlobally()
    
    //  URL Routing
    Routing.Routes["GET", ["/", "/index"] ] = { _ in return IndexHandler() }
    Routing.Routes["GET", ["/session"] ] = { _ in return SessionHandler() }
    Routing.Routes["GET", ["/template"] ] = { _ in return TemplateHandler() }
    Routing.Routes["POST", ["/post"]] = { _ in return PostHandler() }
    Routing.Routes["GET", ["/sqlite", "/sqlite/{json}"]] = { _ in return SqliteHandler() }
    Routing.Routes["POST", ["/sqlite"]] = { _ in return SqliteHandler() }
    Routing.Routes["GET", ["/sqlite/add"]] = { _ in return SqliteAddHandler() }
    Routing.Routes["POST", ["/sqlite/add"]] = { _ in return SqliteAddHandler() }

    print("\(Routing.Routes.description)")
    
    // Create our SQLite database.
    do {
        let sqlite = try SQLite(DB_PATH)
        try sqlite.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT)")
    } catch {
        print("Failure creating database at " + DB_PATH)
    }
}

//  MARK: - extensions
extension WebResponse {
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
            try response.renderHTML("template.mustache", values: values)
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

//  sqlist
class SqliteHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()

            let sqlite = try SQLite(DB_PATH)
            defer { sqlite.close() }
            
            var sql = "SELECT * FROM user"
            var nameForSearch: String?
            if let name = request.postParam("name") {
                nameForSearch = name
                sql = "SELECT * FROM user WHERE name LIKE :1"
            }
            values["nameForSearch"] = nameForSearch ?? ""

            var users = [Any]()
            try sqlite.forEachRow(sql, doBindings: {
                (stmt:SQLiteStmt) -> () in
                    if let nameForSearch = nameForSearch {
                        try stmt.bind(1, "%" + nameForSearch + "%")
                    }
                }) {
                    (stmt:SQLiteStmt, r:Int) -> () in
                    var id:Int?, name:String?
                    (id, name) = (stmt.columnInt(0), stmt.columnText(1))
                    if let id = id {
                        var user = [String:Any]()
                        user["id"] = id
                        user["name"] = name ?? ""
                        users.append(user)
                    }
            }
            
            if let json = request.urlVariables["json"] where json == "json" {
                try response.outputJson(["users": users])
            } else {
                values["users"] = users
                try response.renderHTML("sqlite.mustache", values: values)
            }
        } catch (let e) {
            print(e)
        }
        
        response.requestCompletedCallback()
    }
}

class SqliteAddHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            let sqlite = try SQLite(DB_PATH)
            defer { sqlite.close() }

            //  validate
            guard let _ = request.postParam("name") else {
                response.setStatus(500, message: "invalidate request parameter")
                response.requestCompletedCallback()
                return
            }

            //  insert
            let name = request.postParam("name") ?? ""
            try sqlite.execute("INSERT INTO user (name) VALUES (:1)") {
                (stmt:SQLiteStmt) -> () in
                try stmt.bind(1, name)
            }

            response.redirectTo("/sqlite")
        } catch (let e) {
            print(e)
        }
        
        response.requestCompletedCallback()
    }
}