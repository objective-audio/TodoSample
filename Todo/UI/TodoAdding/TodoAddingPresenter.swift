//
//  TodoAddingPresenter.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

class TodoAddingPresenter {
    var outputPort: TodoOutputPort?
    
    private var pool = ObserverPool()
    
    let todoItemInsertedNotifier = Notifier<Void>()
    
    var addingName: ImmutableHolder<String?> {
        return self.outputPort?.addingName ?? Empty.optStringHolder
    }
    
    var canAddTodoItem: ImmutableHolder<Bool> {
        return self.outputPort?.canAddTodoItem ?? Empty.boolHolder
    }
    
    init(outputPort: TodoOutputPort) {
        self.outputPort = outputPort
        
        self.pool += outputPort.todoItems.chain().guard({ event in
            switch event {
            case .inserted:
                return true
            default:
                return false
            }
        }).receive(self.todoItemInsertedNotifier).end()
    }
}
