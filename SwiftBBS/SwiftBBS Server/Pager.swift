//
//  Pager.swift
//  SwiftBBS
//
//  Created by Takeo Namba on 2016/01/30.
//	Copyright GrooveLab
//

struct Pager {
    let current: Int
    let countPerPage: Int
    let totalCount: Int
    let pages: [Int]
    
    var hasPrev: Bool {
        return current > 1
    }
    var hasNext: Bool {
        return (pages.last ?? 0) > current
    }
    
    init(current: Int, countPerPage: Int, totalCount: Int, pages: [Int]) {
        self.current = current
        self.countPerPage = countPerPage
        self.totalCount = totalCount
        self.pages = pages
    }
    
    init(totalCount: Int, selectOption: SelectOption) {
        let totalPage = (totalCount / selectOption.rows) + (((totalCount % selectOption.rows) > 0) ? 1 : 0)
        var pages = [Int]()
        if totalPage > 0 {
            for i in 1...totalPage {
                pages.append(i)
            }
        }

        self.init(current: selectOption.page, countPerPage: selectOption.rows, totalCount: totalCount, pages: pages)
    }
    
    func toDictionary() ->  [String: Any]? {
        if totalCount == 0 {
            return nil
        }
        
        let pages = self.pages.map { (page) -> [String: Any] in
            return ["page": page, "current": page == current]
        }
        return [
            "hasPrev": hasPrev,
            "hasNext": hasNext,
            "pages": pages,
            "prevPage": current - 1,
            "nextPage": current + 1,
            "countPerPage": countPerPage,
            "totalCount": totalCount,
        ]
    }
}
