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
    
    var todoItems: [TodoItem] {
        return TodoController.shared.todoItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Todo Items"
        
        self.receiver.add(sender: TodoController.shared.eventSender) { [weak self] event in
            switch event {
            case .todoItemAdded(let index):
                self?.addCell(at: index)
            case .todoItemRemoved(let index):
                self?.removeCell(at: index)
            case .todoItemEdited(let index):
                self?.reloadCell(at: index)
            case .historyItemAdded:
                break
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todoItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        let todoItem = self.todoItems[indexPath.row]
        cell.textLabel?.text = todoItem.name
        cell.accessoryType = todoItem.isCompleted ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        TodoController.shared.toggleCompletedTodoItem(at: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            TodoController.shared.deleteTodoItem(at: indexPath.row)
            break
        default:
            break
        }
    }
}

extension TodoViewController {
    func addCell(at row: Int) {
        self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    
    func removeCell(at row: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    
    func reloadCell(at row: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
}
