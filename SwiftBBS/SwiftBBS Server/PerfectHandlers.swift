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

    //  user TODO:update, delete handler
    Routing.Routes["GET", ["/user", "/user/{action}"]] = { _ in return UserHandler() }
    Routing.Routes["POST", ["/user/{action}"]] = { _ in return UserHandler() }

    //  bbs TODO:update, delete handler
    Routing.Routes["GET", ["/bbs", "/bbs/{action}", "/bbs/{action}/{id}"]] = { _ in return BbsHandler() }
    Routing.Routes["POST", ["/bbs/{action}"]] = { _ in return BbsHandler() }

    print("\(Routing.Routes.description)")
    
    // Create our SQLite database.
    do {
        let sqlite = try SQLite(Config.dbPath)    //  TODO:use MySQL
        try sqlite.execute("CREATE TABLE IF NOT EXISTS user (id INTEGER PRIMARY KEY, name TEXT, password TEXT, created_at TEXT)")
        try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS user_name ON user (name)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs (id INTEGER PRIMARY KEY, title TEXT, comment TEXT, user_id INTEGER, created_at TEXT)")
        try sqlite.execute("CREATE TABLE IF NOT EXISTS bbs_comment (id INTEGER PRIMARY KEY, bbs_id INTEGER, comment TEXT, user_id INTEGER, created_at TEXT)")
        try sqlite.execute("CREATE INDEX IF NOT EXISTS bbs_comment_bbs_id ON bbs_comment (bbs_id);")
    } catch (let e){
        print("Failure creating database at " + Config.dbPath)
        print(e)
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
    var action: String {
        return urlVariables["action"] ?? "index"
    }
}

class BaseRequestHandler: RequestHandler {
    var request: WebRequest!
    var response: WebResponse!
    var db: SQLite!

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

    //  repository
    lazy var userReposity: UserRepository = UserRepository(db: self.db)
    lazy var bbsReposity: BbsRepository = BbsRepository(db: self.db)
    lazy var bbsCommentReposity: BbsCommentRepository = BbsCommentRepository(db: self.db)

    func userIdInSession() throws -> Int? {
        let session = response.getSession(Config.sessionName)    //  TODO:configuration session
        guard let userId = session["id"] as? Int else {
            return nil
        }
        
        //  check user table if exists
        guard let _ = try getUser(userId) else {
            return nil
        }
        
        return userId
    }

    func getUser(userId: Int?) throws -> UserEntity? {
        guard let userId = userId else {
            return nil
        }
        
        return try userReposity.findById(userId)
    }

    func handleRequest(request: WebRequest, response: WebResponse) {
        //  initialize
        self.request = request
        self.response = response
        
        defer {
            response.requestCompletedCallback()
        }

        do {
            db = try SQLite(Config.dbPath)
            
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
    
    func checkActionAcl() throws -> ActionAcl {
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
    
    func setLoginUser(inout values: MustacheEvaluationContext.MapType) throws {
        if let loginUser = try getUser(userIdInSession()) {
            values["loginUser"] = loginUser.toDictionary()
        }
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
            try doRegisterAction()
        case "register":
            try registerAction()
        default:
            try mypageAction()
        }
    }
    
    //  MARK: actions
    func mypageAction() throws {
        var values = MustacheEvaluationContext.MapType()
        
        //  show user info if logged
        try setLoginUser(&values)
        try response.renderHTML("user_mypage.mustache", values: values)
    }
        
    func registerAction() throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user_register.mustache", values: values)
    }
        
    func doRegisterAction() throws {
        //  validate TODO:create validaotr
        guard let name = request.param("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let password = request.param("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        let userEntity = UserEntity(id: nil, name: name, password: password, createdAt: nil)
        try userReposity.insert(userEntity)

        //  do login
        if try login(name, password: password) {
            response.redirectTo("/bbs") //  TODO:add login success message
        } else {
            response.redirectTo("/user/login")  //  TODO:add success message
        }
    }
    
    func loginAction() throws {
        let values = MustacheEvaluationContext.MapType()
        try response.renderHTML("user_login.mustache", values: values)
    }

    func doLoginAction() throws {
        //  validate
        guard let loginName = request.param("name") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let loginPassword = request.param("password") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  check exist
        if try login(loginName, password: loginPassword) {
            response.redirectTo("/bbs") //  TODO:add login success message
        } else {
            response.redirectTo("/user/login")  //  TODO:add login failed message
        }
    }
    
    func logoutAction() throws {
        let session = self.response.getSession(Config.sessionName)
        session["id"] = nil
        
        response.redirectTo("/user/login")
    }

    private func login(name: String, password: String) throws -> Bool {
        if let userEntity = try userReposity.findByName(name, password: password), let userId = userEntity.id {
            //  success login
            let session = self.response.getSession(Config.sessionName)
            session["id"] = userId
            return true
        } else {
            return false
        }
    }
}

class BbsHandler: BaseRequestHandler {
    
    override init() {
        super.init()
        
        //  define action acl
        needLoginActions = ["add", "addcomment"]
        redirectUrlIfNotLogin = "/user/login"

//        noNeedLoginActions = []
//        redirectUrlIfLogin = "/"
    }
    
    override func dispatchAction(action: String) throws {
        switch request.action {
        case "add" where request.requestMethod() == "POST":
            try addAction()
        case "addcomment" where request.requestMethod() == "POST":
            try addcommentAction()
        case "detail":
            try detailAction()
        default:
            try listAction()
        }
    }
    
    func listAction() throws {
        let keyword = request.param("keyword")
        let bbsEntities = try bbsReposity.selectByKeyword(keyword)
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()
        values["keyword"] = keyword ?? ""
        values["bbsList"] = bbsEntities.map({ (bbsEntity) -> [String: Any] in
            bbsEntity.toDictionary()
        })
        
        //  show user info if logged
        try setLoginUser(&values)
        try response.renderHTML("bbs_list.mustache", values: values)
    }
    
    func addAction() throws {
        //  validate
        guard let title = request.param("title") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let comment = request.param("comment") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        let entity = BbsEntity(id: nil, title: title, comment: comment, userId: try self.userIdInSession()!, createdAt: nil)
        let storedEntity = try bbsReposity.insert(entity)
        
        if let bbsId = storedEntity.id {
            response.redirectTo("/bbs/detail/\(bbsId)")
        } else {
            response.redirectTo("/bbs")
        }
    }
    
    func detailAction() throws {
        guard let bbsIdString = request.urlVariables["id"], let bbsId = Int(bbsIdString) else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        var values: MustacheEvaluationContext.MapType = MustacheEvaluationContext.MapType()

        //  bbs
        guard let bbsEntity = try bbsReposity.findById(bbsId) else {
            response.setStatus(404, message: "not found bbs")
            return
        }
        values["bbs"] = bbsEntity.toDictionary()
        
        //  bbs post
        let bbsCommentEntities = try bbsCommentReposity.selectByBbsId(bbsId)
        values["postList"] = bbsCommentEntities.map({ (entity) -> [String: Any] in
            entity.toDictionary()
        })
        
        //  show user info if logged
        try setLoginUser(&values)
        try response.renderHTML("bbs_detail.mustache", values: values)
    }
    
    func addcommentAction() throws {
        //  validate
        guard let bbsIdString = request.param("bbs_id"), let bbsId = Int(bbsIdString) else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        guard let comment = request.param("comment") else {
            response.setStatus(500, message: "invalidate request parameter")
            return
        }
        
        //  insert
        let entity = BbsCommentEntity(id: nil, bbsId: bbsId, comment: comment, userId: try userIdInSession()!, createdAt: nil)
        let storedEntity = try bbsCommentReposity.insert(entity)

        response.redirectTo("/bbs/detail/\(storedEntity.bbsId)")
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
        if let val2 = request.param("val2") {
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
            
            let sqlite = try SQLite(Config.dbPath)
            defer { sqlite.close() }
            
            var sql = "SELECT * FROM user"
            var nameForSearch: String?
            if let name = request.param("name") {
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
            let sqlite = try SQLite(Config.dbPath)
            defer { sqlite.close() }

            //  validate
            guard let _ = request.param("name") else {
                response.setStatus(500, message: "invalidate request parameter")
                response.requestCompletedCallback()
                return
            }

            //  insert
            let name = request.param("name") ?? ""
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