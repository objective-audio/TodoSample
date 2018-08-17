//
//  TodoInputPort.swift
//  Todo
//
//  Created by yasoshima on 2018/08/09.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

protocol TodoInputPort: class {
    func firstSetup()
    func addTodoItem(name: String)
    func addingNameChanged(_ name: String?)
    func toggleCompletedTodoItem(at index: Int)
    func deleteTodoItem(at index: Int)
}
