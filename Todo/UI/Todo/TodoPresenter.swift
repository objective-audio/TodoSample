//
//  TodoPresenter.swift
//

import Foundation
import Chaining

class TodoPresenter {
    var outputPort: TodoOutputPort?
    
    init(outputPort: TodoOutputPort) {
        self.outputPort = outputPort
    }
    
    var todoItems: ImmutableArrayHolder<Holder<TodoItem>> {
        return self.outputPort?.todoItems ?? Empty.todoItemArrayHolder
    }
}
