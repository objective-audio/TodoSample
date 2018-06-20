//
//  HistoryViewController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

class HistoryViewController: UITableViewController {
    let cellIdentifier: String = "HistoryCell"
    let receiver = NotificationReceiver()
    
    var histories: [HistoryItem] {
        return TodoController.shared.historyItems
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "History Items"
        
        self.receiver.add(sender: TodoController.shared.eventSender) { [weak self] event in
            switch event {
            case .todoItemAdded:
                break
            case .todoItemRemoved:
                break
            case .historyItemAdded(let index):
                self?.addCell(at: index)
                break
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.histories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = self.histories[indexPath.row].name
        return cell
    }
}

extension HistoryViewController {
    func addCell(at row: Int) {
        self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
}
