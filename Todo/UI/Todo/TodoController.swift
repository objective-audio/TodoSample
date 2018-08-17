//
//  TodoController.swift
//

import Foundation

class TodoController {
    var inputPort: TodoInputPort?
    
    init(inputPort: TodoInputPort) {
        self.inputPort = inputPort
    }
    
    func toggleCompletedTodoItem(at index: Int) {
        self.inputPort?.toggleCompletedTodoItem(at: index)
    }
    
    func deleteTodoItem(at index: Int) {
        self.inputPort?.deleteTodoItem(at: index)
    }
}
