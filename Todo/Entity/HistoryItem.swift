//
//  HistoryItem.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

class HistoryItem {
    let name: String
    let createdAt: Date
    let completedAt: Date
    
    init(name: String, createdAt: Date, completedAt: Date, documentID: String) {
        self.name = name
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

extension HistoryItem: Relayable {
    typealias SendValue = HistoryItem
}
