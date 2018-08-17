//
//  TodoAddingController.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class TodoAddingController {
    var inputPort: TodoInputPort?
    
    init(inputPort: TodoInputPort) {
        self.inputPort = inputPort
    }
    
    func addingNameChanged(_ name: String?) {
        self.inputPort?.addingNameChanged(name)
    }
    
    func addTodoItem(name: String) {
        self.inputPort?.addTodoItem(name: name)
    }
}
