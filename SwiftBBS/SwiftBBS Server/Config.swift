//
//  Config.swift
//  SwiftBBS
//
//  Created by 難波健雄 on 2016/01/02.
//
//

import PerfectLib

class Config {
    static let sessionName = "session"
    static let sessionExpires = 60
    static let dbName = "SwiftBBS"
    static let dbPath = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + dbName
}
