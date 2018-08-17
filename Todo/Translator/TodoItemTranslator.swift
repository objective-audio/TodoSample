//
//  TodoItemTranslator.swift
//  Todo
//
//  Created by yasoshima on 2018/08/09.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

struct TodoItemTranslator {
    static func item(from firebaseData: [String: Any], documentID: String) -> TodoItem? {
        guard let name = firebaseData["name"] as? String else {
            return nil
        }
        
        guard let createdAt = firebaseData["created_at"] as? Date else {
            return nil
        }
        
        guard let isCompleted = firebaseData["is_completed"] as? Bool else {
            return nil
        }
        
        guard let isDeleted = firebaseData["is_deleted"] as? Bool else {
            return nil
        }
        
        return TodoItem(name: name, createdAt: createdAt, isCompleted: isCompleted, isDeleted: isDeleted, documentID: documentID)
    }
    
    static func firebaseData(from item: TodoItem, isDeleted: Bool = false, toggleCompleted: Bool = false) -> [String: Any] {
        let is_completed = toggleCompleted ? !item.isCompleted : item.isCompleted
        return ["name": item.name, "created_at": item.createdAt, "is_completed": is_completed, "is_deleted": isDeleted]
    }
    
    static func newFirebaseData(name: String) -> [String: Any] {
        return ["name": name, "created_at": Date(), "is_completed": false, "is_deleted": false]
    }
}
