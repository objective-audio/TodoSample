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

class TodoUseCase: FlowGraphType {
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
    
    typealias FlowEvent = (kind: FlowEventKind, object: TodoUseCase)
    typealias Event = TodoUseCase.FlowEvent
    
    private let graph: FlowGraph<TodoUseCase>
    private let dataStore: DataStoreGateway
    
    let rawTodoItems = ArrayHolder<Holder<TodoItem>>()
    let rawHistoryItems = ArrayHolder<HistoryItem>()
    let rawIsConnecting = Holder<Bool>(false)
    let rawAddingName = Holder<String?>(nil)
    let rawCanAddTodoItem = Holder<Bool>(false)
    let errorNotifier = Notifier<Error>()
    
    private var pool = ObserverPool()
    
    init(dataStore: DataStoreGateway) {
        self.dataStore = dataStore
        
        let builder = FlowGraphBuilder<TodoUseCase>()
        
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
            
            event.object.setup()
            
            return .run(.loadingTodoItemsEnter, event)
        }
        
        // アイテム取得の通信開始
        builder.add(running: .loadingTodoItemsEnter) { event in
            event.object.rawIsConnecting.value = true
            
            event.object.dataStore.todoItems() { [weak object = event.object] result in
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
        builder.add(waiting: .loadingTodoItems) { event in
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
        builder.add(running: .todoItemsLoadSucceeded) { event in
            event.object.rawIsConnecting.value = false
            
            if case .todoItemsLoadSucceeded(let items) = event.kind {
                event.object.rawTodoItems.replace(items.map { Holder($0) })
                
                return .run(.loadingHistoryItemsEnter, event)
            } else {
                fatalError()
            }
        }
        
        // 履歴取得の通信開始
        builder.add(running: .loadingHistoryItemsEnter) { event in
            event.object.rawIsConnecting.value = true
            
            event.object.dataStore.historyItems() { [weak object = event.object] result in
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
        builder.add(waiting: .loadingHistoryItems) { event in
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
        builder.add(running: .historyItemsLoadSucceeded) { event in
            event.object.rawIsConnecting.value = false
            
            if case .historyItemsLoadSucceeded(let items) = event.kind {
                event.object.rawHistoryItems.replace(items)
                
                return .wait(.operating)
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 操作中
        builder.add(waiting: .operating) { event in
            switch event.kind {
            case .addTodoItem(let name):
                event.object.rawAddingName.value = name
                
                if event.object.rawCanAddTodoItem.value {
                    return .run(.addingTodoItemEnter, event)
                } else {
                    return .stay
                }
            case .removeTodoItem:
                return .run(.removingTodoItemEnter, event)
            case .editTodoItem:
                return .run(.editingTodoItemEnter, event)
            case .addingNameChanged(let name):
                event.object.rawAddingName.value = name
                return .stay
            default:
                return .stay
            }
        }
        
        // アイテム追加の通信開始
        builder.add(running: .addingTodoItemEnter) { event in
            event.object.rawIsConnecting.value = true
            
            if case .addTodoItem(let name) = event.kind {
                
                event.object.dataStore.addTodoItem(name: name) { [weak object = event.object] result in
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
        builder.add(waiting: .addingTodoItem) { event in
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
        builder.add(running: .addTodoItemSucceeded) { event in
            event.object.rawIsConnecting.value = false
            
            if case .todoItemAddSucceeded(let item) = event.kind {
                event.object.rawTodoItems.insert(Holder(item), at: 0)
                event.object.rawAddingName.value = ""
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // アイテム削除の通信開始
        builder.add(running: .removingTodoItemEnter) { event in
            event.object.rawIsConnecting.value = true
            
            if case .removeTodoItem(let index) = event.kind {
                let todoItem = event.object.rawTodoItems[index].value
                
                event.object.dataStore.delete(todoItem: todoItem) { [weak object = event.object] result in
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
        builder.add(waiting: .removingTodoItem) { event in
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
        builder.add(running: .removeTodoItemSucceeded) { event in
            event.object.rawIsConnecting.value = false
            
            if case .todoItemRemoveSucceeded(let index) = event.kind {
                let item = event.object.rawTodoItems.remove(at: index).value
                
                return .run(.addingHistoryItemEnter, (.todoItemRemoved(item), event.object))
            } else {
                fatalError()
            }
        }
        
        // アイテム更新の通信開始
        builder.add(running: .editingTodoItemEnter) { event in
            event.object.rawIsConnecting.value = true
            
            if case .editTodoItem(let index) = event.kind {
                let todoItem = event.object.rawTodoItems[index].value
                
                event.object.dataStore.toggle(todoItem: todoItem) { [weak object = event.object] result in
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
        builder.add(waiting: .editingTodoItem) { event in
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
        builder.add(running: .editTodoItemSucceeded) { event in
            event.object.rawIsConnecting.value = false
            
            if case .todoItemEditSucceeded(let index, let item) = event.kind {
                event.object.rawTodoItems[index].value = item
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 履歴追加の通信開始
        builder.add(running: .addingHistoryItemEnter) { event in
            event.object.rawIsConnecting.value = true
            
            if case .todoItemRemoved(let item) = event.kind {
                event.object.dataStore.addHistoryItem(from: item) { [weak object = event.object] result in
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
        builder.add(waiting: .addingHistoryItem) { event in
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
        builder.add(running: .addHistoryItemSucceeded) { event in
            event.object.rawIsConnecting.value = false
            
            if case .historyItemAddSucceeded(let item) = event.kind {
                event.object.rawHistoryItems.insert(item, at: 0)
            } else {
                fatalError()
            }
            
            return .wait(.operating)
        }
        
        // 通信失敗
        builder.add(running: .connectionFailed) { event in
            if case .connectionFailed(let error) = event.kind {
                event.object.rawIsConnecting.value = false
                event.object.errorNotifier.notify(value: error)
            } else {
                fatalError()
            }
            
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
    
    private func send(flowEvent kind: FlowEventKind) {
        self.graph.run((kind, self))
    }
}

extension TodoUseCase: TodoOutputPort {
    var todoItems: ImmutableArrayHolder<Holder<TodoItem>> {
        return self.rawTodoItems
    }
    
    var historyItems: ImmutableArrayHolder<HistoryItem> {
        return self.rawHistoryItems
    }
    
    var isConnecting: ImmutableHolder<Bool> {
        return self.rawIsConnecting
    }
    
    var addingName: ImmutableHolder<String?> {
        return self.rawAddingName
    }
    
    var canAddTodoItem: ImmutableHolder<Bool> {
        return self.rawCanAddTodoItem
    }
}

extension TodoUseCase: TodoInputPort {
    func firstSetup() {
        self.send(flowEvent: .firstSetup)
    }
    
    func addTodoItem(name: String) {
        self.send(flowEvent: .addTodoItem(name: name))
    }
    
    func addingNameChanged(_ name: String?) {
        self.send(flowEvent: .addingNameChanged(name))
    }
    
    func toggleCompletedTodoItem(at index: Int) {
        self.send(flowEvent: .editTodoItem(at: index))
    }
    
    func deleteTodoItem(at index: Int) {
        self.send(flowEvent: .removeTodoItem(at: index))
    }
}

extension TodoUseCase {
    func setup() {
        self.pool += self.rawIsConnecting.chain().do({ value in
            if value {
                UIApplication.shared.beginIgnoringInteractionEvents()
            } else {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        }).end()
        
        self.pool += self.rawAddingName.chain().to({ name in
            guard let name = name else {
                return false
            }
            return !name.isEmpty
        }).receive(self.rawCanAddTodoItem).sync()
    }
}
