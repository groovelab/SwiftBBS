//
//  Repository.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/09.
//  Copyright GrooveLab
//

import PerfectLib
import MySQL

enum RepositoryError : ErrorType {
    case Fail(Int)
    case Select(Int)
    case Insert(Int)
    case Update(Int)
    case Delete(Int)
}

class Repository {
    typealias Params = [Any]
    typealias Row = [Any?]
    typealias Rows = [Row]
    typealias MySQLText = [UInt8]
    
    let db: MySQL!
    lazy var nowSql: String = "cast(now() as datetime)"

    init(db: MySQL) {
        self.db = db
    }

    func executeInsertSql(sql: String, params: Params?) throws -> UInt {
        do {
            return try executeSql(sql, params: params) {
                UInt($0.insertId())
            }
        } catch RepositoryError.Fail(let errorCode) {
            throw RepositoryError.Insert(errorCode)
        }
    }
    
    func executeUpdateSql(sql: String, params: Params?) throws -> UInt {
        do {
            return try executeSql(sql, params: params) {
                UInt($0.affectedRows())
            }
        } catch RepositoryError.Fail(let errorCode) {
            throw RepositoryError.Update(errorCode)
        }
    }
    
    func executeDeleteSql(sql: String, params: Params?) throws -> UInt {
        do {
            return try executeSql(sql, params: params) {
                UInt($0.affectedRows())
            }
        } catch RepositoryError.Fail(let errorCode) {
            throw RepositoryError.Delete(errorCode)
        }
    }
    
    func executeSelectSql(sql: String, params: Params?) throws -> Rows {
        do {
            return try executeSql(sql, params: params) { stmt -> Rows in
                let results = stmt.results()
                defer { results.close() }
                
                var rows = Rows()
                if !results.forEachRow({ rows.append($0) }) {
                    throw RepositoryError.Select(Int(stmt.errorCode()))
                }
                return rows
            }
        } catch RepositoryError.Fail(let errorCode) {
            throw RepositoryError.Select(errorCode)
        }
    }

    func stringFromMySQLText(text: MySQLText?) -> String? {
        guard let text = text else { return nil }
        return UTF8Encoding.encode(text)
    }

    func intFromMySQLCount(count: Any) -> Int {
        if let count = count as? UInt64 {
            //  for linux
            return Int(count)
        } else if let count = count as? Int64 {
            //  for mac
            return Int(count)
        }
        return count as! Int
    }

    private func executeSql<T>(sql: String, params: Params?, @noescape completion: ((MySQLStmt) throws -> T)) throws -> T {
        let stmt = MySQLStmt(db)
        defer { stmt.close() }
        
        if !stmt.prepare(sql) {
            throw RepositoryError.Fail(Int(stmt.errorCode()))
        }
        
        stmt.bindParams(params)
        
        if !stmt.execute() {
            debugPrint(stmt)
            throw RepositoryError.Fail(Int(stmt.errorCode()))
        }
        
        return try completion(stmt)
    }
}
