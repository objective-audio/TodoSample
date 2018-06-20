//
//  TodoViewController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

class TodoViewController: UITableViewController {
    let cellIdentifier: String = "TodoCell"
    let receiver = NotificationReceiver()
    
    var todoController: TodoController {
        return AppController.shared.todoController
    }
    
    var todos: [TodoItem] {
        return self.todoController.todoItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Todo Items"
        
        self.receiver.add(sender: self.todoController.eventSender) { [weak self] event in
            switch event {
            case .todoItemAdded(let index):
                self?.addCell(at: index)
            case .todoItemRemoved(let index):
                self?.removeCell(at: index)
            case .historyItemAdded:
                break
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = self.todos[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.todoController.completeTodoItem(at: indexPath.row)
    }
}

extension TodoViewController {
    func addCell(at row: Int) {
        self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    
    func removeCell(at row: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
}
