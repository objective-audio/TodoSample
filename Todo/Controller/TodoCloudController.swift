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
import Chaining

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
        case loadingHistoryItemsEnter
        case historyItemsLoadSucceeded
        
        case addingTodoItemEnter
        case addTodoItemSucceeded
        
        case removingTodoItemEnter
        case removeTodoItemSucceeded
        
        case editingTodoItemEnter
        case editTodoItemSucceeded
        
        case addingHistoryItemEnter
        case addHistoryItemSucceeded
        
        case connectionFailed
    }
    
    enum FlowEventKind {
        // 外部からのイベント
        case firstSetup
        case loadTodoItems
        case addTodoItem(name: String)
        case removeTodoItem(at: Int)
        case editTodoItem(at: Int)
        case addingNameChanged(String?)
        
        // 内部からのイベント
        case todoItemsLoadSucceeded(items: [TodoItem])
        case historyItemsLoadSucceeded(items: [HistoryItem])
        case todoItemAddSucceeded(item: TodoItem)
        case todoItemRemoveSucceeded(at: Int)
        case todoItemEditSucceeded(at: Int, item: TodoItem)
        case todoItemRemoved(_: TodoItem)
        case historyItemAddSucceeded(item: HistoryItem)
        
        case connectionFailed(error: Error)
    }
    
    typealias FlowEvent = (kind: FlowEventKind, object: TodoCloudController)
    
    private let graph = FlowGraph<WaitingState, RunningState, FlowEvent>()
    
    // 外部へ公開するパラメータ
    
    let todoItems = ArrayHolder<Holder<TodoItem>>()
    let historyItems = ArrayHolder<HistoryItem>()
    
    private(set) var isConnecting = Holder<Bool>(false)
    private(set) var addingName = Holder<String?>(nil)
    private(set) var canAddTodoItem = Holder<Bool>(false)
    
    let errorNotifier = Notifier<Error>()
    private var pool = ObserverPool()
    
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
        self.graph.add(waiting: .begin) { event in
            switch event.kind {
            case .firstSetup:
                return .run(.firstSetup, event)
            default:
                return .stay
            }
        }
        
        // 初期セットアップ
        self.graph.add(running: .firstSetup) { event in
            FirebaseApp.configure()
            
            event.object.setup()
            
            return .run(.loadingTodoItemsEnter, event)
        }
        
        // アイテム取得の通信開始
        self.graph.add(running: .loadingTodoItemsEnter) { event in
            event.object.isConnecting.value = true
            
            CloudStore.todoItems() { [weak object = event.object] result in
                guard let object = object else {
                    return
                }
                
                switch result {
                case .success(let items):
                    object.send(flowEvent: .todoItemsLoadSucceeded(items: items))
                case .failed(let error):
                    object.send(flowEvent: .connectionFailed(error: error))
                }
            }
            
            return .wait(.loadingTodoItems)
        }
        
        // アイテム取得の通信を待つ
        self.graph.add(waiting: .loadingTodoItems) { event in
            switch event.kind {
            case .todoItemsLoadSucceeded:
                return .run(.todoItemsLoadSucceeded, event)
            case .connectionFailed:
                return .run(.connectionFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテムの取得成功
        self.graph.add(running: .todoItemsLoadSucceeded) { event in
            event.object.isConnecting.value = false
            
            if case .todoItemsLoadSucceeded(let items) = event.kind {
                event.object.todoItems.replace(items.map { Holder($0) })
                
                return .run(.loadingHistoryItemsEnter, event)
            } else {
                fatalError()
            }
        }
        
        // 履歴取得の通信開始
        self.graph.add(running: .loadingHistoryItemsEnter) { event in
            event.object.isConnecting.value = true
            
            CloudStore.historyItems() { [weak object = event.object] result in
                guard let object = object else {
                    return
                }
                
                switch result {
                case .success(let items):
                    object.send(flowEvent: .historyItemsLoadSucceeded(items: items))
                case .failed(let error):
                    object.send(flowEvent: .connectionFailed(error: error))
                }
            }
            
            return .wait(.loadingHistoryItems)
        }
        
        // 履歴取得中
        self.graph.add(waiting: .loadingHistoryItems) { event in
            switch event.kind {
            case .historyItemsLoadSucceeded:
                return .run(.historyItemsLoadSucceeded, event)
            case .connectionFailed:
                return .run(.connectionFailed, event)
            default:
                return .stay
            }
        }
        
        // 履歴取得成功
        self.graph.add(running: .historyItemsLoadSucceeded) { event in
            event.object.isConnecting.value = false
            
            if case .historyItemsLoadSucceeded(let items) = event.kind {
                event.object.historyItems.replace(items)
                
                return .wait(.operating)
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 操作中
        self.graph.add(waiting: .operating) { event in
            switch event.kind {
            case .addTodoItem(let name):
                event.object.addingName.value = name
                
                if event.object.canAddTodoItem.value {
                    return .run(.addingTodoItemEnter, event)
                } else {
                    return .stay
                }
            case .removeTodoItem:
                return .run(.removingTodoItemEnter, event)
            case .editTodoItem:
                return .run(.editingTodoItemEnter, event)
            case .addingNameChanged(let name):
                event.object.addingName.value = name
                return .stay
            default:
                return .stay
            }
        }
        
        // アイテム追加の通信開始
        self.graph.add(running: .addingTodoItemEnter) { event in
            event.object.isConnecting.value = true
            
            if case .addTodoItem(let name) = event.kind {
                
                CloudStore.addTodoItem(name: name) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success(let item):
                        object.send(flowEvent: .todoItemAddSucceeded(item: item))
                    case .failed(let error):
                        object.send(flowEvent: .connectionFailed(error: error))
                    }
                }
            } else {
                fatalError()
            }
            
            return .wait(.addingTodoItem)
        }
        
        // アイテム追加の通信中
        self.graph.add(waiting: .addingTodoItem) { event in
            switch event.kind {
            case .todoItemAddSucceeded:
                return .run(.addTodoItemSucceeded, event)
            case .connectionFailed:
                return .run(.connectionFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテム追加成功
        self.graph.add(running: .addTodoItemSucceeded) { event in
            event.object.isConnecting.value = false
            
            if case .todoItemAddSucceeded(let item) = event.kind {
                event.object.todoItems.insert(Holder(item), at: 0)
                event.object.addingName.value = ""
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // アイテム削除の通信開始
        self.graph.add(running: .removingTodoItemEnter) { event in
            event.object.isConnecting.value = true
            
            if case .removeTodoItem(let index) = event.kind {
                let sendItem = event.object.todoItems[index].value
                
                CloudStore.delete(todoItem: sendItem) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success:
                        object.send(flowEvent: .todoItemRemoveSucceeded(at: index))
                    case .failed(let error):
                        object.send(flowEvent: .connectionFailed(error: error))
                    }
                }
            }
            
            return .wait(.removingTodoItem)
        }
        
        // アイテム削除の通信中
        self.graph.add(waiting: .removingTodoItem) { event in
            switch event.kind {
            case .todoItemRemoveSucceeded:
                return .run(.removeTodoItemSucceeded, event)
            case .connectionFailed:
                return .run(.connectionFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテム削除成功
        self.graph.add(running: .removeTodoItemSucceeded) { event in
            event.object.isConnecting.value = false
            
            if case .todoItemRemoveSucceeded(let index) = event.kind {
                let item = event.object.todoItems.remove(at: index).value
                
                return .run(.addingHistoryItemEnter, (.todoItemRemoved(item), event.object))
            } else {
                fatalError()
            }
        }
        
        // アイテム更新の通信開始
        self.graph.add(running: .editingTodoItemEnter) { event in
            event.object.isConnecting.value = true
            
            if case .editTodoItem(let index) = event.kind {
                let sendItem = event.object.todoItems[index].value
                
                CloudStore.toggle(todoItem: sendItem) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success(let item):
                        object.send(flowEvent: .todoItemEditSucceeded(at: index, item: item))
                    case .failed(let error):
                        object.send(flowEvent: .connectionFailed(error: error))
                    }
                }
            }
            
            return .wait(.editingTodoItem)
        }
        
        // アイテム更新の通信中
        self.graph.add(waiting: .editingTodoItem) { event in
            switch event.kind {
            case .todoItemEditSucceeded:
                return .run(.editTodoItemSucceeded, event)
            case .connectionFailed:
                return .run(.connectionFailed, event)
            default:
                return .stay
            }
        }
        
        // アイテム更新成功
        self.graph.add(running: .editTodoItemSucceeded) { event in
            event.object.isConnecting.value = false
            
            if case .todoItemEditSucceeded(let index, let item) = event.kind {
                event.object.todoItems[index].value = item
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 履歴追加の通信開始
        self.graph.add(running: .addingHistoryItemEnter) { event in
            event.object.isConnecting.value = true
            
            if case .todoItemRemoved(let item) = event.kind {
                CloudStore.addHistoryItem(from: item) { [weak object = event.object] result in
                    guard let object = object else {
                        return
                    }
                    
                    switch result {
                    case .success(let item):
                        object.send(flowEvent: .historyItemAddSucceeded(item: item))
                    case .failed(let error):
                        object.send(flowEvent: .connectionFailed(error: error))
                    }
                }
            } else {
                fatalError()
            }
            
            return .wait(.addingHistoryItem)
        }
        
        // 履歴追加の通信中
        self.graph.add(waiting: .addingHistoryItem) { event in
            switch event.kind {
            case .historyItemAddSucceeded:
                return .run(.addHistoryItemSucceeded, event)
            case .connectionFailed:
                return .run(.connectionFailed, event)
            default:
                return .stay
            }
        }
        
        // 履歴追加成功
        self.graph.add(running: .addHistoryItemSucceeded) { event in
            event.object.isConnecting.value = false
            
            if case .historyItemAddSucceeded(let item) = event.kind {
                event.object.historyItems.insert(item, at: 0)
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 通信失敗
        self.graph.add(running: .connectionFailed) { event in
            if case .connectionFailed(let error) = event.kind {
                event.object.isConnecting.value = false
                event.object.errorNotifier.notify(value: error)
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        for state in WaitingState.cases {
            assert(self.graph.contains(state: .waiting(state)))
        }
        
        for state in RunningState.cases {
            assert(self.graph.contains(state: .running(state)))
        }
        
        self.graph.begin(with: .begin)
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
    
    func addingNameChanged(_ name: String?) {
        self.send(flowEvent: .addingNameChanged(name))
    }
    
    private func send(flowEvent kind: FlowEventKind) {
        self.graph.run((kind, self))
    }
}

extension TodoCloudController {
    func setup() {
        self.pool += self.isConnecting.chain().do({ value in
            if value {
                UIApplication.shared.beginIgnoringInteractionEvents()
            } else {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        }).end()
        
        self.pool += self.addingName.chain().to({ name in
            guard let name = name else {
                return false
            }
            return !name.isEmpty
        }).receive(self.canAddTodoItem).sync()
    }
}
