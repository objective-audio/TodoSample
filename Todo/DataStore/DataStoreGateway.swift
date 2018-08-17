//
//  DataStoreGateway.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

protocol DataStoreGateway {
    func todoItems(completion: @escaping (Result<[TodoItem]>) -> Void)
    func addTodoItem(name: String, completion: @escaping (Result<TodoItem>) -> Void)
    func delete(todoItem: TodoItem, completion: @escaping (Result<Void>) -> Void)
    func toggle(todoItem: TodoItem, completion: @escaping (Result<TodoItem>) -> Void)
    func historyItems(completion: @escaping (Result<[HistoryItem]>) -> Void)
    func addHistoryItem(from todoItem: TodoItem, completion: @escaping (Result<HistoryItem>) -> Void)
}
