//
//  TodoViewController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit
import Chaining

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
    
    let presenter = TodoPresenter(outputPort: AppManager.shared.todoUseCase)
    let controller = TodoController(inputPort: AppManager.shared.todoUseCase)
    
    var observer: AnyObserver?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Todo Items"
        
        self.observer = self.presenter.todoItems.chain().do({ [weak self] event in
            switch event {
            case .all:
                self?.reloadAllCells()
            case .inserted(let index, _):
                self?.addCell(at: index)
            case .removed(let index, _):
                self?.removeCell(at: index)
            case .replaced(let index, _), .relayed(_, let index, _):
                self?.reloadCell(at: index)
            }
        }).sync()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .adding:
            return 1
        case .editing:
            return self.presenter.todoItems.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: section.cellIdentifier(), for: indexPath)
        
        switch section {
        case .adding:
            break
        case .editing:
            let todoItem = self.presenter.todoItems.element(at: indexPath.row).value
            cell.textLabel?.text = todoItem.name
            cell.accessoryType = todoItem.isCompleted ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .editing = Section(rawValue: indexPath.section)! {
            self.controller.toggleCompletedTodoItem(at: indexPath.row)
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
            self.controller.deleteTodoItem(at: indexPath.row)
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
