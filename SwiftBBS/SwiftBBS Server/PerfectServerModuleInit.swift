//
//  PerfectHandlers.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/01.
//  Copyright GrooveLab
//

import PerfectLib
import MySQL

//  MARK: - init
public func PerfectServerModuleInit() {
    Routing.Handler.registerGlobally()
    
    //  URL Routing
    Routing.Routes["GET", ["/assets/*/*"]] = { _ in return StaticFileHandler() }
    Routing.Routes["GET", ["/uploads/*"]] = { _ in return StaticFileHandler() }
    
    //  user
    Routing.Routes["GET", ["/user", "/user/{action}"]] = { _ in return UserHandler() }
    Routing.Routes["POST", ["/user/{action}"]] = { _ in return UserHandler() }

    //  bbs
    Routing.Routes["GET", ["/", "/bbs", "/bbs/{action}", "/bbs/{action}/{id}"]] = { _ in return BbsHandler() }
    Routing.Routes["POST", ["/bbs/{action}"]] = { _ in return BbsHandler() }

    //  oauth
    Routing.Routes["GET", ["/oauth/{action}"]] = { _ in return OAuthHandler() }
    
    print("\(Routing.Routes.description)")

    //  Create MySQL Tables
    do {
        let dbManager = try DatabaseManager()
        try dbManager.query("CREATE TABLE IF NOT EXISTS user (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100), password VARCHAR(100), provider VARCHAR(100), provider_user_id VARCHAR(100), provider_user_name VARCHAR(100), created_at DATETIME, updated_at DATETIME, UNIQUE(name), UNIQUE(provider, provider_user_id))")
        try dbManager.query("CREATE TABLE IF NOT EXISTS bbs (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, title TEXT, comment TEXT, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME)")
        try dbManager.query("CREATE TABLE IF NOT EXISTS bbs_comment (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, bbs_id INT UNSIGNED, comment TEXT, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME, KEY(bbs_id))")
        try dbManager.query("CREATE TABLE IF NOT EXISTS image (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, parent VARCHAR(20), parent_id INT UNSIGNED, path TEXT, ext VARCHAR(10), original_name TEXT, width INT UNSIGNED, height INT UNSIGNED, user_id INT UNSIGNED, created_at DATETIME, updated_at DATETIME, KEY(parent, parent_id))")
        
        
        
//        try dbManager.query("CREATE TABLE IF NOT EXISTS testtest (a TINYINT, au TINYINT UNSIGNED, b SMALLINT, bu SMALLINT UNSIGNED, c MEDIUMINT, cu MEDIUMINT UNSIGNED, d INT, du INT UNSIGNED, e BIGINT, eu BIGINT UNSIGNED)")
//        try dbManager.query("INSERT INTO testtest (a, au, b, bu, c, cu, d, du, e, eu) VALUES (-1, 1, -2, 2, -3, 3, -4, 4, -5, 5)")
        
        
        try dbManager.query("CREATE TABLE IF NOT EXISTS `all_data_types` (`char` CHAR( 10 ),`varchar` VARCHAR( 20 ),`tinytext` TINYTEXT,`mediumtext` MEDIUMTEXT,`text` TEXT,`longtext` LONGTEXT,"
            + "`tinyint` TINYINT,`utinyint` TINYINT UNSIGNED,`smallint` SMALLINT,`usmallint` SMALLINT UNSIGNED,`mediumint` MEDIUMINT,`umediumint` MEDIUMINT UNSIGNED,"
            + "`int` INT,`uint` INT UNSIGNED,`bigint` BIGINT,`ubigint` BIGINT UNSIGNED,"
            + "`float` FLOAT( 10, 2 ),`double` DOUBLE,`decimal` DECIMAL( 10, 2 ),"
            + "`date` DATE,`datetime` DATETIME,`timestamp` TIMESTAMP,`time` TIME,`year` YEAR,"
            + "`tinyblob` TINYBLOB,`mediumblob` MEDIUMBLOB,`blob` BLOB,`longblob` LONGBLOB,"
            + "`enum` ENUM( '1', '2', '3' ),`set` SET( '1', '2', '3' ),`bool` BOOL,"
            + "`binary` BINARY( 20 ),`varbinary` VARBINARY( 20 ) )")

        try dbManager.query("DELETE FROM all_data_types")

        try dbManager.query("INSERT INTO all_data_types (`char`,`varchar`,`tinytext`,`mediumtext`,`text`,`longtext`,"
            + "`tinyint`,`utinyint`,`smallint`,`usmallint`,`mediumint`,`umediumint`,"
            + "`int`,`uint`,`bigint`,`ubigint`,"
            + "`float`, `double`, `decimal`,"
            + "`date`, `datetime`, `timestamp`, `time`,`year`,"
            + "`tinyblob`, `mediumblob`, `blob`,`longblob`,"
            + "`enum`,`set`,`bool`,"
            + "`binary`,`varbinary` ) VALUES ("
            + "'a','abc','tiny text','medium text','text','long text',"
            + "-1, 1, -2, 2, -3, 3,"
            + "-4, 4, -5, 5,"
            + "1.1, 2.2, 123,"
            + "'2015-10-21','2015-10-21 11:22:33','2015-10-21 11:22:33','11:22:33','2016',"
            + "'abc','abc','abc','abc',"
            + "'1','2',true,"
            + "'1','2')")
        try dbManager.query("SELECT * FROM all_data_types LIMIT 1")
        let results = try dbManager.storeResults()
        defer { results.close() }
        while let row = results.next() {
            print(row)
        }
        
        try dbManager.query("DELETE FROM all_data_types")
        
        
        let stmt1 = MySQLStmt(dbManager.db)
        defer { stmt1.close() }
        let prepRes = stmt1.prepare("INSERT INTO all_data_types VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
//        print(prepRes)
        stmt1.bindParam("a")
        stmt1.bindParam("abc")
        stmt1.bindParam("tiny text")
        stmt1.bindParam("medium text")
        stmt1.bindParam("text")
        stmt1.bindParam("long text")
        stmt1.bindParam(-1)
        stmt1.bindParam(1)
        stmt1.bindParam(-2)
        stmt1.bindParam(2)
        stmt1.bindParam(-3)
        stmt1.bindParam(3)
        stmt1.bindParam(-4)
        stmt1.bindParam(4)
        stmt1.bindParam(-5)
        stmt1.bindParam(5)
        stmt1.bindParam(1.1)
        stmt1.bindParam(2.2)
        stmt1.bindParam(123)
        stmt1.bindParam("2015-10-21")
        stmt1.bindParam("2015-10-21 11:22:33")
        stmt1.bindParam("2015-10-21 11:22:33")
        stmt1.bindParam("11:22:33")
        stmt1.bindParam("2016")

        stmt1.bindParam("tinyblob")
//        "tinyblob".withCString { stmt1.bindParam($0, length: 8) }
        "mediumblob".withCString { stmt1.bindParam($0, length: 10) }
        "blob".withCString { stmt1.bindParam($0, length: 4) }
        "longblob".withCString { stmt1.bindParam($0, length: 8) }
        stmt1.bindParam("1")
        stmt1.bindParam("2")
        stmt1.bindParam(1)
        stmt1.bindParam("1")
        stmt1.bindParam("2")
        let execRes = stmt1.execute()
//        print(execRes)
        
        let stmt2 = MySQLStmt(dbManager.db)
        defer { stmt2.close() }
        let prepRes2 = stmt2.prepare("SELECT * FROM all_data_types")
//        print(prepRes2)
        let execRes2 = stmt2.execute()
        let results2 = stmt2.results()
        defer { results2.close() }
        results2.forEachRow { row in
            print("char", row[0] as! String)
            print("varchar", row[1] as! String)
            print("tinytext", UTF8Encoding.encode(row[2] as! [UInt8]))
            print("mediumtext", UTF8Encoding.encode(row[3] as! [UInt8]))
            print("text", UTF8Encoding.encode(row[4] as! [UInt8]))
            print("longtext", UTF8Encoding.encode(row[5] as! [UInt8]))
            print("tinyint", row[6] as! Int8)
            print("utinyint", row[7] as! UInt8)
            print("smallint", row[8] as! Int16)
            print("usmallint", row[9] as! UInt16)
            print("mediumint", row[10] as! Int32)
            print("umediumint", row[11] as! UInt32)
            print("int", row[12] as! Int32)
            print("uint", row[13] as! UInt32)
            print("bigint", row[14] as! Int64)
            print("ubigint", row[15] as! UInt64)
            print("float", row[16] as! Float)
            print("double", row[17] as! Double)
            print("decimal", row[18] as! String)
            print("date", row[19] as! String)
            print("datetime", row[20] as! String)
            print("timestamp", row[21] as! String)
            print("time", row[22] as! String)
            print("year", row[23] as! String)
            print("tinyblob", UTF8Encoding.encode(row[24] as! [UInt8]))
            print("mediumblob", UTF8Encoding.encode(row[25] as! [UInt8]))
            print("blob", UTF8Encoding.encode(row[26] as! [UInt8]))
            print("longblob", UTF8Encoding.encode(row[27] as! [UInt8]))
            print("enum", row[28] as! String)
            print("set", row[29] as! String)
            print("bool", row[30] as! Int8)
            print("binary", row[31] as! String)
            print("varbinary", row[32] as! String)
        }


    } catch {
        print(error)
    }
}

enum DatabaseError : ErrorType {
    case Connect(String)
    case Query(String)
    case StoreResults
}

class DatabaseManager {
    let db: MySQL
    
    init() throws {
        db = MySQL()
        if db.connect(Config.mysqlHost, user: Config.mysqlUser, password: Config.mysqlPassword, db: Config.mysqlDb) == false {
            throw DatabaseError.Connect(db.errorMessage())
        }
    }
    
    func query(sql: String) throws {
        if db.query(sql) == false {
            throw DatabaseError.Query(db.errorMessage())
        }
    }
    
    func storeResults() throws -> MySQL.Results {
        guard let results = db.storeResults() else {
            throw DatabaseError.StoreResults
        }
        return results
    }
}



