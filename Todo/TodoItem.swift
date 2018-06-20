//
//  TodoItem.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class TodoItem: Codable {
    let name: String
    let createdAt: Date
    
    init(name: String, createdAt: Date) {
        self.name = name
        self.createdAt = createdAt
    }
    
    func json() -> String? {
        if let data = try? JSONEncoder().encode(self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    static func item(from json: String) -> TodoItem? {
        if let data = json.data(using: .utf8), let item = try? JSONDecoder().decode(TodoItem.self, from: data) {
            return item
        }
        return nil
    }
}
