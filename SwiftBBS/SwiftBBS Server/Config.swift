//
//  Config.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/02.
//	Copyright GrooveLab
//

import PerfectLib

class Config {
    static let sessionName = "session"
    static let sessionExpires = 60
    static let dbName = "SwiftBBS"
    static let dbPath = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + dbName
}
