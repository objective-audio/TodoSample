//
//  HistoryItem.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class HistoryItem: Codable {
    let name: String
    let createdAt: Date
    let completedAt: Date
    
    init(name: String, createdAt: Date, completedAt: Date) {
        self.name = name
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
    
    func json() -> String? {
        let encoder = JSONEncoder()
        
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    static func item(from json: String) -> HistoryItem? {
        if let data = json.data(using: .utf8), let item = try? JSONDecoder().decode(HistoryItem.self, from: data) {
            return item
        }
        return nil
    }
}
