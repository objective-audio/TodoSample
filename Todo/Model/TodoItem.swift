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
    let isCompleted: Bool
    let documentID: String
    
    init(name: String, createdAt: Date, isCompleted: Bool, isDeleted: Bool, documentID: String) {
        self.name = name
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.documentID = documentID
    }
    
    func firebaseData(isDeleted: Bool = false, toggleCompleted: Bool = false) -> [String: Any] {
        let is_completed = toggleCompleted ? !self.isCompleted : self.isCompleted
        return ["name": self.name, "created_at": self.createdAt, "is_completed": is_completed, "is_deleted": isDeleted]
    }
    
    static func addingFirebaseData(name: String) -> [String: Any] {
        return ["name": name, "created_at": Date(), "is_completed": false, "is_deleted": false]
    }
    
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
}
