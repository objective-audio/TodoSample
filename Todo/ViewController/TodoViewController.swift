//
//  TodoViewController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

class TodoViewController: UITableViewController {
    enum Section: Int {
        case adding
        case editing
        
        func cellIdentifier() -> String {
            switch self {
            case .adding:
                return "AddingCell"
            case .editing:
                return "TodoCell"
            }
        }
    }
    
    let receiver = NotificationReceiver()
    
    var todoItems: [TodoItem] {
        return TodoCloudController.shared.todoItems
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Todo Items"
        
        self.receiver.add(sender: TodoCloudController.shared.eventSender) { [weak self] event in
            switch event {
            case .todoItemsLoaded:
                self?.reloadAllCells()
            case .historyItemsLoaded:
                break // 履歴は表示しない
            case .todoItemAdded(let index):
                self?.addCell(at: index)
            case .todoItemRemoved(let index):
                self?.removeCell(at: index)
            case .todoItemEdited(let index):
                self?.reloadCell(at: index)
                
            case .todoItemsLoadError,
                 .todoItemAddError,
                 .todoItemEditError,
                 .todoItemRemoveError,
                 .historyItemsLoadError,
                 .historyItemAdded,
                 .historyItemAddError,
                 .beginConnection,
                 .endConnection:
                // 何もしない
                break
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .adding:
            return 1
        case .editing:
            return self.todoItems.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: section.cellIdentifier(), for: indexPath)
        
        switch section {
        case .adding:
            break
        case .editing:
            let todoItem = self.todoItems[indexPath.row]
            cell.textLabel?.text = todoItem.name
            cell.accessoryType = todoItem.isCompleted ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .editing = Section(rawValue: indexPath.section)! {
            TodoCloudController.shared.toggleCompletedTodoItem(at: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch Section(rawValue: indexPath.section)! {
        case .adding:
            return false
        case .editing:
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch (section, editingStyle) {
        case (.editing, .delete):
            TodoCloudController.shared.deleteTodoItem(at: indexPath.row)
            break
        default:
            break
        }
    }
}

extension TodoViewController {
    func reloadAllCells() {
        self.tableView.reloadData()
    }
    
    func addCell(at row: Int) {
        self.tableView.insertRows(at: [IndexPath(row: row, section: Section.editing.rawValue)], with: .automatic)
    }
    
    func removeCell(at row: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: row, section: Section.editing.rawValue)], with: .automatic)
    }
    
    func reloadCell(at row: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: row, section: Section.editing.rawValue)], with: .automatic)
    }
}
