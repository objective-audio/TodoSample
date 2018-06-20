//
//  DataStore.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class DataStore {
    static let todoItemsKey = "todoItems"
    static let historyItemsKey = "historyItems"
    
    func save(todoItems: [TodoItem], historyItems: [HistoryItem]) {
        let todoJsons = todoItems.compactMap { $0.json() }
        let historyJsons = historyItems.compactMap { $0.json() }
        
        UserDefaults.standard.set(todoJsons, forKey: DataStore.todoItemsKey)
        UserDefaults.standard.set(historyJsons, forKey: DataStore.historyItemsKey)
    }
    
    func load() -> (todoItems: [TodoItem], historyItems: [HistoryItem]) {
        var todoItems: [TodoItem] = []
        var historyItems: [HistoryItem] = []
        
        if let todoJsons = UserDefaults.standard.array(forKey: DataStore.todoItemsKey) as? [String] {
            todoItems = todoJsons.compactMap { TodoItem.item(from: $0) }
        }
        
        if let historyJsons = UserDefaults.standard.array(forKey: DataStore.historyItemsKey) as? [String] {
            historyItems = historyJsons.compactMap { HistoryItem.item(from: $0) }
        }
        
        return (todoItems, historyItems)
    }
}
