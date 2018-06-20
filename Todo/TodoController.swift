//
//  TodoController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class TodoController {
    private(set) var todoItems: [TodoItem]
    private(set) var historyItems: [HistoryItem]
    private let dataStore: DataStore
    
    enum Event {
        case todoItemAdded(at :Int)
        case todoItemRemoved(at :Int)
        case historyItemAdded(at: Int)
    }
    
    class EventSender: NotificationSendable {
        typealias Context = Event
        static let notificationName = Notification.Name("TodoControllerNotification")
    }
    
    let eventSender = EventSender()
    
    init() {
        let dataStore = DataStore()
        self.dataStore = dataStore
        
        let loaded = dataStore.load()
        
        self.todoItems = loaded.todoItems
        self.historyItems = loaded.historyItems
    }
    
    func addTodoItem(name: String) {
        self.todoItems = [TodoItem(name: name, createdAt: Date())] + self.todoItems
        
        self.save()
        
        self.eventSender.post(context: .todoItemAdded(at: 0))
    }
    
    func completeTodoItem(at index: Int) {
        let removed = self.todoItems.remove(at: index)
        self.historyItems = [HistoryItem(name: removed.name, createdAt: removed.createdAt, completedAt: Date())] + self.historyItems
        
        self.save()
        
        self.eventSender.post(context: .todoItemRemoved(at: index))
        self.eventSender.post(context: .historyItemAdded(at: 0))
    }
    
    func save() {
        self.dataStore.save(todoItems: self.todoItems, historyItems: self.historyItems)
    }
}