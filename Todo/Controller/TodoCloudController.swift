//
//  TodoCloudController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/28.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import FlowGraph
import Firebase

class TodoCloudController {
    static let shared = TodoCloudController()
    
    // FlowGraph関連
    
    enum WaitingState: EnumEnumerable {
        case begin
        case loadingTodoItems
        case loadingHistoryItems
        case operating
        case addingTodoItem
        case removingTodoItem
        case editingTodoItem
        case addingHistoryItem
    }
    
    enum RunningState: EnumEnumerable {
        case firstSetup
        case loadingTodoItemsEnter
        case todoItemsLoadSucceeded
        case todoItemsLoadFailed
        case loadingHistoryItemsEnter
        case historyItemsLoadSucceeded
        case historyItemsLoadFailed
        
        case addingTodoItemEnter
        case addTodoItemSucceeded
        case addTodoItemFailed
        
        case removingTodoItemEnter
        case removeTodoItemSucceeded
        case removeTodoItemFailed
        
        case editingTodoItemEnter
        case editTodoItemSucceeded
        case editTodoItemFailed
        
        case addingHistoryItemEnter
        case addHistoryItemSucceeded
        case addHistoryItemFailed
    }
    
    enum FlowEventKind {
        // 外部からのイベント
        case firstSetup
        case loadTodoItems
        case addTodoItem(name: String)
        case removeTodoItem(at: Int)
        case editTodoItem(at: Int)
        
        // 内部からのイベント
        case todoItemsLoadSucceeded(items: [TodoItem])
        case todoItemsLoadFailed(error: Error)
        
        case historyItemsLoadSucceeded(items: [HistoryItem])
        case historyItemsLoadFailed(error: Error)
        
        case todoItemAddSucceeded(item: TodoItem)
        case todoItemAddFailed(error: Error)
        
        case todoItemRemoveSucceeded(at: Int)
        case todoItemRemoveFailed(error: Error)
        
        case todoItemEditSucceeded(at: Int, item: TodoItem)
        case todoItemEditFailed(error: Error)
        
        case todoItemRemoved(_: TodoItem)
        case historyItemAddSucceeded(item: HistoryItem)
        case historyItemAddFailed(error: Error)
    }
    
    typealias FlowEvent = (kind: FlowEventKind, object: TodoCloudController)
    
    private let graph: FlowGraph<WaitingState, RunningState, FlowEvent>
    
    // Notification関連
    
    enum ViewEvent {
        case todoItemsLoaded
        case todoItemsLoadError
        
        case historyItemsLoaded
        case historyItemsLoadError
        
        case todoItemAdded(at: Int)
        case todoItemAddError
        
        case todoItemEdited(at: Int)
        case todoItemEditError
        
        case todoItemRemoved(at: Int)
        case todoItemRemoveError
        
        case historyItemAdded(at: Int)
        case historyItemAddError
        
        case beginConnection
        case endConnection
    }
    
    class EventSender: NotificationSendable {
        typealias Context = ViewEvent
        static let notificationName = Notification.Name("TodoCloudControllerNotification")
    }
    
    let eventSender = EventSender()
    
    // 外部へ公開するパラメータ
    
    private(set) var todoItems: [TodoItem] = []
    private(set) var historyItems: [HistoryItem] = []
    private(set) var lastError: Error?
    
    var is_connecting: Bool {
        switch self.graph.state {
        case .waiting(.loadingTodoItems),
             .waiting(.addingTodoItem),
             .waiting(.removingTodoItem),
             .running(.loadingTodoItemsEnter),
             .running(.addingTodoItemEnter),
             .running(.removingTodoItemEnter):
            return true
        default:
            return false
        }
    }
    
    init() {
        let builder = FlowGraphBuilder<WaitingState, RunningState, FlowEvent>()
        
        builder.add(waiting: .begin) { event in
            switch event.kind {
            case .firstSetup:
                return .run(.firstSetup, event)
            default:
                return .stay
            }
        }
        
        // 初期セットアップ
        builder.add(running: .firstSetup) { event in
            FirebaseApp.configure()
            
            return .run(.loadingTodoItemsEnter, event)
        }
        
        // アイテム取得の通信開始
        builder.add(running: .loadingTodoItemsEnter) { event in
            event.object.postBeginConnection()
            
            CloudStore.todoItems() { [weak object = event.object] result in
                guard let object = object else {
                    return
                }
                
                switch result {
                case .success(let items):
                    object.send(flowEvent: .todoItemsLoadSucceeded(items: items))
                case .failed(let error):
                    object.lastError = error
                    object.send(flowEvent: .todoItemsLoadFailed(error: error))
                }
            }
            
            return .wait(.loadingTodoItems)
        }
        
        // アイテム取得の通信を待つ
        builder.add(waiting: .loadingTodoItems) { event in
            switch event.kind {
            case .todoItemsLoadSucceeded:
                return .run(.todoItemsLoadSucceeded, event)
            case .todoItemsLoadFailed:
                return .run(.todoItemsLoadFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテムの取得成功
        builder.add(running: .todoItemsLoadSucceeded) { event in
            event.object.postEndConnection()
            
            if case .todoItemsLoadSucceeded(let items) = event.kind {
                event.object.todoItems = items
                event.object.eventSender.post(context: .todoItemsLoaded)
                
                return .run(.loadingHistoryItemsEnter, event)
            } else {
                fatalError()
            }
        }
        
        // アイテムの取得失敗
        builder.add(running: .todoItemsLoadFailed) { event in
            event.object.postEndConnection()
            event.object.eventSender.post(context: .todoItemsLoadError)
            
            return .wait(.operating)
        }
        
        // 履歴取得の通信開始
        builder.add(running: .loadingHistoryItemsEnter) { event in
            event.object.postBeginConnection()
            
            CloudStore.historyItems() { [weak object = event.object] result in
                guard let object = object else {
                    return
                }
                
                switch result {
                case .success(let items):
                    object.send(flowEvent: .historyItemsLoadSucceeded(items: items))
                case .failed(let error):
                    object.lastError = error
                    object.send(flowEvent: .historyItemsLoadFailed(error: error))
                }
            }
            
            return .wait(.loadingHistoryItems)
        }
        
        // 履歴取得中
        builder.add(waiting: .loadingHistoryItems) { event in
            switch event.kind {
            case .historyItemsLoadSucceeded:
                return .run(.historyItemsLoadSucceeded, event)
            case .historyItemsLoadFailed:
                return .run(.historyItemsLoadFailed, event)
            default:
                return .stay
            }
        }
        
        // 履歴取得成功
        builder.add(running: .historyItemsLoadSucceeded) { event in
            event.object.postEndConnection()
            
            if case .historyItemsLoadSucceeded(let items) = event.kind {
                event.object.historyItems = items
                event.object.eventSender.post(context: .historyItemsLoaded)
                
                return .wait(.operating)
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 履歴取得失敗
        builder.add(running: .historyItemsLoadFailed) { event in
            event.object.postEndConnection()
            event.object.eventSender.post(context: .historyItemsLoadError)
            
            return .wait(.operating)
        }
        
        // 操作中
        builder.add(waiting: .operating) { event in
            // TODO
            switch event.kind {
            case .addTodoItem:
                return .run(.addingTodoItemEnter, event)
            case .removeTodoItem:
                return .run(.removingTodoItemEnter, event)
            case .editTodoItem:
                return .run(.editingTodoItemEnter, event)
            default:
                return .stay
            }
        }
        
        // アイテム追加の通信開始
        builder.add(running: .addingTodoItemEnter) { event in
            event.object.postBeginConnection()
            
            if case .addTodoItem(let name) = event.kind {
                
                CloudStore.addTodoItem(name: name) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success(let item):
                        object.send(flowEvent: .todoItemAddSucceeded(item: item))
                    case .failed(let error):
                        object.send(flowEvent: .todoItemAddFailed(error: error))
                    }
                }
            } else {
                fatalError()
            }
            
            return .wait(.addingTodoItem)
        }
        
        // アイテム追加の通信中
        builder.add(waiting: .addingTodoItem) { event in
            switch event.kind {
            case .todoItemAddSucceeded:
                return .run(.addTodoItemSucceeded, event)
            case .todoItemAddFailed:
                return .run(.addTodoItemFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテム追加成功
        builder.add(running: .addTodoItemSucceeded) { event in
            event.object.postEndConnection()
            
            if case .todoItemAddSucceeded(let item) = event.kind {
                event.object.todoItems.insert(item, at: 0)
                event.object.eventSender.post(context: .todoItemAdded(at: 0))
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // アイテム追加失敗
        builder.add(running: .addTodoItemFailed) { event in
            event.object.postEndConnection()
            event.object.eventSender.post(context: .todoItemAddError)
            
            return .wait(.operating)
        }
        
        // アイテム削除の通信開始
        builder.add(running: .removingTodoItemEnter) { event in
            event.object.postBeginConnection()
            
            if case .removeTodoItem(let index) = event.kind {
                let sendItem = event.object.todoItems[index]
                
                CloudStore.delete(todoItem: sendItem) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success:
                        object.send(flowEvent: .todoItemRemoveSucceeded(at: index))
                    case .failed(let error):
                        object.send(flowEvent: .todoItemRemoveFailed(error: error))
                    }
                }
            }
            
            return .wait(.removingTodoItem)
        }
        
        // アイテム削除の通信中
        builder.add(waiting: .removingTodoItem) { event in
            switch event.kind {
            case .todoItemRemoveSucceeded:
                return .run(.removeTodoItemSucceeded, event)
            case .todoItemRemoveFailed:
                return .run(.removeTodoItemFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテム削除成功
        builder.add(running: .removeTodoItemSucceeded) { event in
            event.object.postEndConnection()
            
            if case .todoItemRemoveSucceeded(let index) = event.kind {
                let item = event.object.todoItems.remove(at: index)
                event.object.eventSender.post(context: .todoItemRemoved(at: index))
                
                return .run(.addingHistoryItemEnter, (.todoItemRemoved(item), event.object))
            } else {
                fatalError()
            }
        }
        
        // アイテム削除失敗
        builder.add(running: .removeTodoItemFailed) { event in
            event.object.postEndConnection()
            event.object.eventSender.post(context: .todoItemRemoveError)
            
            return .wait(.operating)
        }
        
        // アイテム更新の通信開始
        builder.add(running: .editingTodoItemEnter) { event in
            event.object.postBeginConnection()
            
            if case .editTodoItem(let index) = event.kind {
                let sendItem = event.object.todoItems[index]
                
                CloudStore.toggle(todoItem: sendItem) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success(let item):
                        object.send(flowEvent: .todoItemEditSucceeded(at: index, item: item))
                    case .failed(let error):
                        object.send(flowEvent: .todoItemEditFailed(error: error))
                    }
                }
            }
            
            return .wait(.editingTodoItem)
        }
        
        // アイテム更新の通信中
        builder.add(waiting: .editingTodoItem) { event in
            switch event.kind {
            case .todoItemEditSucceeded:
                return .run(.editTodoItemSucceeded, event)
            case .todoItemEditFailed:
                return .run(.editTodoItemFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテム更新成功
        builder.add(running: .editTodoItemSucceeded) { event in
            event.object.postEndConnection()
            
            if case .todoItemEditSucceeded(let index, let item) = event.kind {
                event.object.todoItems.remove(at: index)
                event.object.todoItems.insert(item, at: index)

                event.object.eventSender.post(context: .todoItemEdited(at: index))
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // アイテム更新失敗
        builder.add(running: .editTodoItemFailed) { event in
            event.object.postEndConnection()
            event.object.eventSender.post(context: .todoItemEditError)
            
            return .wait(.operating)
        }
        
        // 履歴追加の通信開始
        builder.add(running: .addingHistoryItemEnter) { event in
            event.object.postBeginConnection()
            
            if case .todoItemRemoved(let item) = event.kind {
                CloudStore.addHistoryItem(from: item) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success(let item):
                        object.send(flowEvent: .historyItemAddSucceeded(item: item))
                    case .failed(let error):
                        object.send(flowEvent: .historyItemAddFailed(error: error))
                    }
                }
            } else {
                fatalError()
            }
            
            return .wait(.addingHistoryItem)
        }
        
        // 履歴追加の通信中
        builder.add(waiting: .addingHistoryItem) { event in
            switch event.kind {
            case .historyItemAddSucceeded:
                return .run(.addHistoryItemSucceeded, event)
            case .historyItemAddFailed:
                return .run(.addHistoryItemFailed, event)
            default:
                return .stay
            }
        }
        
        // 履歴追加成功
        builder.add(running: .addHistoryItemSucceeded) { event in
            event.object.postEndConnection()
            
            if case .historyItemAddSucceeded(let item) = event.kind {
                event.object.historyItems.insert(item, at: 0)

                event.object.eventSender.post(context: .historyItemAdded(at: 0))
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 履歴追加失敗
        builder.add(running: .addHistoryItemFailed) { event in
            event.object.postEndConnection()
            event.object.eventSender.post(context: .historyItemAddError)
            
            return .wait(.operating)
        }
        
        for state in WaitingState.cases {
            assert(builder.contains(state: .waiting(state)))
        }
        
        for state in RunningState.cases {
            assert(builder.contains(state: .running(state)))
        }
        
        self.graph = builder.build(initial: .begin)
    }
    
    func firstSetup() {
        self.send(flowEvent: .firstSetup)
    }
    
    func addTodoItem(name: String) {
        self.send(flowEvent: .addTodoItem(name: name))
    }
    
    func toggleCompletedTodoItem(at index: Int) {
        self.send(flowEvent: .editTodoItem(at: index))
    }
    
    func deleteTodoItem(at index: Int) {
        self.send(flowEvent: .removeTodoItem(at: index))
    }
    
    private func send(flowEvent kind: FlowEventKind) {
        self.graph.run((kind, self))
    }
    
    private func postBeginConnection() {
        self.eventSender.post(context: .beginConnection)
        UIApplication.shared.beginIgnoringInteractionEvents()
        print("begin connection")
    }
    
    private func postEndConnection() {
        UIApplication.shared.endIgnoringInteractionEvents()
        self.eventSender.post(context: .endConnection)
        
        print("end connection")
    }
}
