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
    
    init(name: String, createdAt: Date, completedAt: Date, documentID: String) {
        self.name = name
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
    
    static func addingFirebaseData(todoItem: TodoItem) -> [String: Any] {
        return ["name": todoItem.name, "created_at": todoItem.createdAt, "completed_at": Date(), "is_deleted": false]
    }
    
    static func item(from firebaseData: [String: Any], documentID: String) -> HistoryItem? {
        guard let name = firebaseData["name"] as? String else {
            return nil
        }
        
        guard let createdAt = firebaseData["completed_at"] as? Date else {
            return nil
        }
        
        guard let completedAt = firebaseData["completed_at"] as? Date else {
            return nil
        }
        
        return HistoryItem(name: name, createdAt: createdAt, completedAt: completedAt, documentID: documentID)
    }
}
