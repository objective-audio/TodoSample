//
//  TodoItem.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

class TodoItem {
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
}

extension TodoItem: Relayable {
    typealias SendValue = TodoItem
}
