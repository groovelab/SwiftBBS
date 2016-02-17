//
//  SelectOption.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/30.
//  Copyright GrooveLab
//

struct SelectOption {
    static let DEFAULT_ROWS = 20
    
    let page: Int
    let rows: Int
    
    var limit: Int {
        return rows
    }
    var offset: Int {
        let offset = (page - 1) * rows
        return offset < 0 ? 0 : offset
    }
    
    init(page: Int, rows: Int) {
        self.page = page
        self.rows = rows
    }
    
    init(page: Int) {
        self.init(page: page, rows: SelectOption.DEFAULT_ROWS)
    }
    
    init(page: String?, rows: String?) {
        self.init(page: Int(page ?? "") ?? 1, rows: Int(rows ?? "") ?? SelectOption.DEFAULT_ROWS)
    }
    
    func limitOffsetSql() -> String {
        return "LIMIT \(limit) OFFSET \(offset)"
    }
}
