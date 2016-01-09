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
    //  sample
    //  TODO:move to sample
    Routing.Routes["GET", ["/", "/index"] ] = { _ in return IndexHandler() }
    Routing.Routes["GET", ["/session"] ] = { _ in return SessionHandler() }
    Routing.Routes["GET", ["/template"] ] = { _ in return TemplateHandler() }
    Routing.Routes["POST", ["/post"]] = { _ in return PostHandler() }
    Routing.Routes["GET", ["/sqlite", "/sqlite/{json}"]] = { _ in return SqliteHandler() }
    Routing.Routes["POST", ["/sqlite"]] = { _ in return SqliteHandler() }
    Routing.Routes["GET", ["/sqlite/add"]] = { _ in return SqliteAddHandler() }
    Routing.Routes["POST", ["/sqlite/add"]] = { _ in return SqliteAddHandler() }

    //  user
    Routing.Routes["GET", ["/user", "/user/{action}"]] = { _ in return UserHandler() }
    Routing.Routes["POST", ["/user/{action}"]] = { _ in return UserHandler() }

    //  bbs
    Routing.Routes["GET", ["/bbs", "/bbs/{action}", "/bbs/{action}/{id}"]] = { _ in return BbsHandler() }
    Routing.Routes["POST", ["/bbs/{action}"]] = { _ in return BbsHandler() }

    print("\(Routing.Routes.description)")
    
    // Create our SQLite database.
    do {
        let sqlite = try SQLite(DB_PATH)    //  TODO:use MySQL
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
}

extension WebRequest {
    func postParam(targetKey: String) -> String? {
        let keyValues = postParams.filter { (key, value) -> Bool in
            return (targetKey == key)
        }
        
        //  TODO:consider array param like <input type="text" name="key[]">
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

class BaseRequestHandler: RequestHandler {
    var request: WebRequest!
    var response: WebResponse!

    //  action acl
    enum ActionAcl {
        case NeedLogin
        case NoNeedLogin
        case None
    }

    var needLoginActions: [String] = []
    var noNeedLoginActions: [String] = []
    var redirectUrlIfLogin: String?
    var redirectUrlIfNotLogin: String?

    func userIdInSession() throws -> Int? {
        let session = response.getSession(Config.sessionName)    //  TODO:configuration session
        guard let userId = session["id"] as? Int else {
            return nil
        }
        
        //  check user table if exists
        guard let _ = try getUser(userId) else {
            return nil
        }
        
        //  TODO:set user data in session
        return userId
    }

    func getUser(userId: Int?) throws -> [String: Any]? {
        guard let userId = userId else {
            return nil
        }
        
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
        
        var loginUser = [String: Any]()
        
        let sql = "SELECT id, name FROM user WHERE id = :1"
        try sqlite.forEachRow(sql, doBindings: {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, userId)
            }) {
                (stmt:SQLiteStmt, r:Int) -> () in
                var id: Int?, name: String?
                (id, name) = (stmt.columnInt(0), stmt.columnText(1))
                if let id = id {
                    loginUser = ["id": id, "name": name ?? ""]
                }
        }
        
        if loginUser.count == 0 {
            return nil
        }
        return loginUser
    }

    func handleRequest(request: WebRequest, response: WebResponse) {
        //  initialize
        self.request = request
        self.response = response
        
        defer {
            response.requestCompletedCallback()
        }
        
        do {
            switch try checkActionAcl() {
            case .NeedLogin:
                if let redirectUrl = redirectUrlIfNotLogin {
                    response.redirectTo(redirectUrl)
                    return
                }
            case .NoNeedLogin:
                if let redirectUrl = redirectUrlIfLogin {
                    response.redirectTo(redirectUrl)
                    return
                }
            case .None:
                break
            }

            try dispatchAction(request.action)
        } catch (let e) {
            print(e)
        }
    }
    
    func dispatchAction(action: String) throws {
        //  need implement in subclass
    }
    
    private func checkActionAcl() throws -> ActionAcl {
        if let _ = try userIdInSession() {
            //  already login
            if noNeedLoginActions.contains(request.action) {
                return .NoNeedLogin
            }
        } else {
            //  not yet login
            if needLoginActions.contains(request.action) {
                return .NeedLogin
            }
        }
        
        return .None
    }
}

//  MARK: - handlers
class UserHandler: BaseRequestHandler {
    
    override init() {
        super.init()
        
        //  define action acl
        needLoginActions = ["index", "mypage", "logout"]
        redirectUrlIfNotLogin = "/user/login"

        noNeedLoginActions = ["login", "add"]
        redirectUrlIfLogin = "/bbs"
    }
    
    override func dispatchAction(action: String) throws {
        switch request.action {
        case "login" where request.requestMethod() == "POST":
            try doLoginAction()
        case "login":
            try loginAction()
        case "logout":
            try logoutAction()
        case "register" where request.requestMethod() == "POST":
            try addAction()
        case "register":
            try registerAction()
        default:
            try mypageAction()
        }
    }
    
    //  MARK: actions
    private func mypageAction() throws {
        var values = MustacheEvaluationContext.MapType()
        values["user"] = try getUser(userIdInSession())
        try response.renderHTML("user_mypage.mustache", values: values)
    }
        
    private func registerAction() throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user_register.mustache", values: values)
    }
        
    private func addAction() throws {
        //  TODO:refactor like DI
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
            
        //  validate TODO:create validaotr
        guard let name = request.postParam("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let password = request.postParam("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert TODO:create User model class
        try sqlite.execute("INSERT INTO user (name, password, created_at) VALUES (:1, :2, datetime('now'))") {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, name)
            try stmt.bind(2, password)  //  TODO:encrypto
        }
        
        if sqlite.errCode() > 0 {
            response.setStatus(500, message: String(sqlite.errCode()) + " : " + sqlite.errMsg())
            return
        }
        
        //  TODO:do login
        
        response.redirectTo("/user/login")  //  TODO:add success message
    }
    
    private func loginAction() throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user_login.mustache", values: values)
    }

    private func doLoginAction() throws {
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
                let session = self.response.getSession(Config.sessionName)
                session["id"] = id
                successLogin = true
            }
        }
        
        if successLogin {
            response.redirectTo("/bbs") //  TODO:add login success message
        } else {
            response.redirectTo("/user/login")  //  TODO:add login failed message
        }
    }
    
    private func logoutAction() throws {
        let session = self.response.getSession(Config.sessionName)
        session.getLoadResult()
        session["id"] = nil
        
        response.redirectTo("/user/login")
    }
}

class BbsHandler: BaseRequestHandler {
    override init() {
        super.init()
        
        //  define action acl
        needLoginActions = ["add", "addpost"]
        redirectUrlIfNotLogin = "/user/login"

//        noNeedLoginActions = []
//        redirectUrlIfLogin = "/"
    }
    
    override func dispatchAction(action: String) throws {
        switch request.action {
        case "add" where request.requestMethod() == "POST":
            try addAction()
        case "addpost" where request.requestMethod() == "POST":
            try addpostAction()
        case "list":
            try listAction()
        default:
            try indexAction()
        }
    }
    
    func indexAction() throws {
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }
        
        var sql = "SELECT b.id, b.title, b.created_at, u.name FROM bbs AS b INNER JOIN user as u ON u.id = b.user_id"
        var keywordForSearch: String?
        if let keyword = request.postParam("keyword") {
            keywordForSearch = keyword
            sql = "SELECT b.id, b.title, b.created_at, u.name FROM bbs AS b INNER JOIN user as u ON u.id = b.user_id WHERE b.title LIKE :1 OR b.comment LIKE :1"
        }
        
        var bbsList = [[String:Any]]()
        try sqlite.forEachRow(sql, doBindings: {
            (stmt:SQLiteStmt) -> () in
            if let keywordForSearch = keywordForSearch {
                try stmt.bind(1, "%" + keywordForSearch + "%")
            }
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            var id:Int?, title:String?, createdAt:String?, name:String?
            (id, title, createdAt, name) = (stmt.columnInt(0), stmt.columnText(1), stmt.columnText(2), stmt.columnText(3))
            if let id = id {
                bbsList.append(["id": id, "title": title ?? "", "createdAt": createdAt ?? "", "name": name ?? 0])   //  TODO:add bbs.comment
            }
        }
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["keywordForSearch"] = keywordForSearch ?? ""
        values["bbsList"] = bbsList
        
        //  show user info if logged
        if let loginUser = try getUser(userIdInSession()) {
            values["loginUser"] = loginUser
        }
        
        try response.renderHTML("bbs.mustache", values: values)
    }
    
    func addAction() throws {
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
            try stmt.bind(3, self.userIdInSession()!)
        }
        
        if sqlite.errCode() > 0 {
            response.setStatus(500, message: String(sqlite.errCode()) + " : " + sqlite.errMsg())
            return
        }

        response.redirectTo("/bbs")
    }
    
    func listAction() throws {
        guard let bbsId = request.urlVariables["id"] else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        let sqlite = try SQLite(DB_PATH)
        defer { sqlite.close() }

        //  bbs
        var bbs = [String:Any]()
        let sql = "SELECT b.id, b.title, b.comment, b.created_at, u.name FROM bbs as b INNER JOIN user AS u ON u.id = b.user_id WHERE b.id = :1"
        try sqlite.forEachRow(sql, doBindings: {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, bbsId)
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            var id:Int?, title:String?, comment:String?, createdAt:String?, name:String?
            (id, title, comment, createdAt, name) = (stmt.columnInt(0), stmt.columnText(1), stmt.columnText(2), stmt.columnText(3), stmt.columnText(4))
            if let id = id {
                bbs = ["id": id, "title": title ?? "", "comment": comment ?? "", "createdAt": createdAt ?? "", "name": name ?? ""]
            }
        }
        
        //  bbs post
        var postList = [[String:Any]]()
        let sql2 = "SELECT b.id, b.comment, b.created_at, u.name FROM bbs_post AS b INNER JOIN user AS u ON u.id = b.user_id WHERE b.bbs_id = :1 ORDER BY b.id"
        try sqlite.forEachRow(sql2, doBindings: {
            (stmt:SQLiteStmt) -> () in
            try stmt.bind(1, bbsId)
        }) {
            (stmt:SQLiteStmt, r:Int) -> () in
            var id:Int?, comment:String?, createdAt:String?, name:String?
            (id, comment, createdAt, name) = (stmt.columnInt(0), stmt.columnText(1), stmt.columnText(2), stmt.columnText(3))
            if let id = id {
                postList.append(["id": id, "comment": comment ?? "", "createdAt": createdAt ?? "", "name": name ?? ""])
            }
        }
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["bbs"] = bbs
        values["postList"] = postList
        
        //  show user info if logged
        if let loginUser = try getUser(userIdInSession()) {
            values["loginUser"] = loginUser
        }

        try response.renderHTML("bbs_list.mustache", values: values)
    }
    
    func addpostAction() throws {
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
            try stmt.bind(3, self.userIdInSession()!)
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