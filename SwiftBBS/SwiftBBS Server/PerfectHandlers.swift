//            var users = [Any]()
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

    //  user register
    Routing.Routes["GET", ["/user", "/user/{action}"]] = { _ in return UserHandler() }
    Routing.Routes["POST", ["/user/{action}"]] = { _ in return UserHandler() }

    //  bbs
    Routing.Routes["GET", ["/bbs", "/bbs/{action}", "/bbs/{action}/{id}"]] = { _ in return BbsHandler() }
    Routing.Routes["POST", ["/bbs/{action}"]] = { _ in return BbsHandler() }

    //  mypage
    
    print("\(Routing.Routes.description)")
    
    // Create our SQLite database.
    do {
        let sqlite = try SQLite(DB_PATH)
        try sqlite.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT, password TEXT, created_at TEXT)")
        try sqlite.execute("CREATE UNIQUE INDEX user_name ON user (name)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs (id INTEGER PRIMARY KEY, title TEXT, comment TEXT, user_id INTEGER, created_at TEXT)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs_post (id INTEGER PRIMARY KEY, bbs_id INTEGER, comment TEXT, user_id INTEGER, created_at TEXT)")
        try sqlite.execute("CREATE INDEX bbs_post_bbs_id ON bbs_post (bbs_id);")
    } catch {
        print("Failure creating database at " + DB_PATH)
    }
}

//  MARK: - extensions
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
    
    func userIdInSession() -> Int? {
        let session = getSession(Config.sessionName)
        guard let id = session["id"] as? Int else {
            return nil
        }
        
        //  TODO:check user table if exists
        return id
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
    
    var action: String {
        return urlVariables["action"] ?? "index"
    }
}

//  MARK: - handlers
class UserHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        //  check session
        if let _ = response.userIdInSession() {
            response.redirectTo("/bbs")
            response.requestCompletedCallback()
            return
        }

        do {
            switch request.action {
            case "login" where request.requestMethod() == "POST":
                try doLoginAction(request, response: response)
            case "login":
                try loginAction(request, response: response)
            case "add" where request.requestMethod() == "POST":
                try addAction(request, response: response)
            default:
                try indexAction(request, response: response)
            }
        } catch (let e) {
            print(e)
        }
        
        response.requestCompletedCallback()
    }
    
    func indexAction(request: WebRequest, response: WebResponse) throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user.mustache", values: values)
    }
    
    func addAction(request: WebRequest, response: WebResponse) throws {
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
            
        //  validate
        guard let name = request.postParam("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let password = request.postParam("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        try sqlite.execute("INSERT INTO user (name, password, created_at) VALUES (:1, :2, datetime('now'))") {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, name)
            try stmt.bind(2, password)  //  TODO:encrypto
        }
        
        if sqlite.errCode() > 0 {
            response.setStatus(500, message: String(sqlite.errCode()) + " : " + sqlite.errMsg())
            return
        }
        
        response.redirectTo("/user/login")
    }
    
    func loginAction(request: WebRequest, response: WebResponse) throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("login.mustache", values: values)
    }

    func doLoginAction(request: WebRequest, response: WebResponse) throws {
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
        
        //  validate
        guard let loginName = request.postParam("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let loginPassword = request.postParam("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  check exist
        var successLogin = false
        let sql = "SELECT id FROM user WHERE name = :1 AND password = :2"
        try sqlite.forEachRow(sql, doBindings: {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, loginName)
            try stmt.bind(2, loginPassword)
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            let id:Int? = stmt.columnInt(0)
            if let id = id {
                let session = response.getSession(Config.sessionName)
                session["id"] = id
                successLogin = true
            }
        }
        
        if successLogin {
            response.redirectTo("/bbs")
        } else {
            response.redirectTo("/user/login")  //  TODO:add login failed message
        }
    }
}

class BbsHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            switch request.action {
            case "add" where request.requestMethod() == "POST":
                try addAction(request, response: response)
            case "addpost" where request.requestMethod() == "POST":
                try addpostAction(request, response: response)
            case "list":
                try listAction(request, response: response)
            default:
                try indexAction(request, response: response)
            }
        } catch (let e) {
            print(e)
        }
        
        response.requestCompletedCallback()
    }
    
    func indexAction(request: WebRequest, response: WebResponse) throws {
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
        
        var sql = "SELECT id, title, user_id, created_at FROM bbs"//  TODO:add user info
        var keywordForSearch: String?
        if let keyword = request.postParam("keyword") {
            keywordForSearch = keyword
            sql = "SELECT id, title, user_id, created_at FROM bbs WHERE title LIKE :1 OR comment LIKE :1"
        }
        
        var bbsList = [[String:Any]]()
        try sqlite.forEachRow(sql, doBindings: {
            (stmt:SQLiteStmt) -> () in
            if let keywordForSearch = keywordForSearch {
                try stmt.bind(1, "%" + keywordForSearch + "%")
            }
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            var id:Int?, title:String?, userId:Int?, createdAt:String?
            (id, title, userId, createdAt) = (stmt.columnInt(0), stmt.columnText(1), stmt.columnInt(2), stmt.columnText(3))
            if let id = id {
                bbsList.append(["id": id, "title": title ?? "", "userId": userId ?? 0, "createdAt": createdAt ?? ""])
            }
        }
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["keywordForSearch"] = keywordForSearch ?? ""
        values["bbsList"] = bbsList
        
        //  TODO: show user info if logged
        
        try response.renderHTML("bbs.mustache", values: values)
    }
    
    func addAction(request: WebRequest, response: WebResponse) throws {
        //  check session
        guard let userId = response.userIdInSession() else {
            response.redirectTo("/bbs")
            return
        }

        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
        
        //  validate
        guard let title = request.postParam("title") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let comment = request.postParam("comment") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        try sqlite.execute("INSERT INTO bbs (title, comment, user_id, created_at) VALUES (:1, :2, :3, datetime('now'))") {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, title)
            try stmt.bind(2, comment)
            try stmt.bind(3, userId)
        }
        
        if sqlite.errCode() > 0 {
            response.setStatus(500, message: String(sqlite.errCode()) + " : " + sqlite.errMsg())
            return
        }

        response.redirectTo("/bbs")
    }
    
    func listAction(request: WebRequest, response: WebResponse) throws {
        guard let bbsId = request.urlVariables["id"] else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }

        //  bbs
        var bbs = [String:Any]()
        let sql = "SELECT id, title, comment FROM bbs WHERE id = :1"//  TODO:add user info
        try sqlite.forEachRow(sql, doBindings: {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, bbsId)
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            var id:Int?, title:String?, comment:String?
            (id, title, comment) = (stmt.columnInt(0), stmt.columnText(1), stmt.columnText(2))
            if let id = id {
                bbs = ["id":id, "title":title ?? "", "comment":comment ?? ""]
            }
        }
        
        //  bbs post
        var postList = [[String:Any]]()
        let sql2 = "SELECT id, comment, user_id, created_at FROM bbs_post WHERE bbs_id = :1 ORDER BY id" //  TODO:add user info
        try sqlite.forEachRow(sql2, doBindings: {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, bbsId)
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            var id:Int?, comment:String?, userId:Int?, createdAt:String?
            (id, comment, userId, createdAt) = (stmt.columnInt(0), stmt.columnText(1), stmt.columnInt(2), stmt.columnText(3))
            if let id = id {
                postList.append(["id": id, "comment": comment ?? "", "userId": userId ?? 0, "createdAt": createdAt ?? ""])
            }
        }
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["bbs"] = bbs
        values["postList"] = postList
        
        //  TODO: show user info if logged

        try response.renderHTML("bbs_list.mustache", values: values)
    }
    
    func addpostAction(request: WebRequest, response: WebResponse) throws {
        //  check session
        guard let userId = response.userIdInSession() else {
            response.redirectTo("/user/login")
            return
        }

        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
        
        //  validate
        guard let bbsId = request.postParam("bbs_id") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let comment = request.postParam("comment") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        try sqlite.execute("INSERT INTO bbs_post (bbs_id, comment, user_id, created_at) VALUES (:1, :2, :3, datetime('now'))") {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, bbsId)
            try stmt.bind(2, comment)
            try stmt.bind(3, userId)
        }
        
        if sqlite.errCode() > 0 {
            response.setStatus(500, message: String(sqlite.errCode()) + " : " + sqlite.errMsg())
            return
        }

        response.redirectTo("/bbs/list/" + bbsId)
    }
}

//  MARK: - sample handlers
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
            var isJson = false
            if let json = request.urlVariables["json"] where json == "json" {
                isJson = true
            }
            
            let sqlite = try SQLite(DB_PATH)
            defer { sqlite.close() }
            
            var sql = "SELECT * FROM user"
            var nameForSearch: String?
            if let name = request.postParam("name") {
                nameForSearch = name
                sql = "SELECT * FROM user WHERE name LIKE :1"
            }

            var usersForJson = [Any]()
            var users = [[String:Any]]()
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
                        if isJson {
                            var user = [String:Any]()
                            user["id"] = id
                            user["name"] = name ?? ""
                            usersForJson.append(user)
                        } else {
                            users.append(["id":id, "name":name ?? ""])
                        }
                    }
            }
            
            if isJson {
                try response.outputJson(["users": usersForJson])
            } else {
                var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
                values["nameForSearch"] = nameForSearch ?? ""
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