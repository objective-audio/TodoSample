//
//  HistoryItemTranslator.swift
//  Todo
//
//  Created by yasoshima on 2018/08/09.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

struct HistoryItemTranslator {
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
    
    static func newFirebaseData(todoItem: TodoItem) -> [String: Any] {
        return ["name": todoItem.name, "created_at": todoItem.createdAt, "completed_at": Date(), "is_deleted": false]
    }
}
