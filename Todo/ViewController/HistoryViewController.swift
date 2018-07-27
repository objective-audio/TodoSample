//
//  HistoryViewController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit
import SwiftChaining

class HistoryViewController: UITableViewController {
    let cellIdentifier: String = "HistoryCell"
    var observer: AnyObserver?
    
    var historyItems: [HistoryItem] {
        return TodoCloudController.shared.historyItems.elements
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "History Items"
        
        self.observer = TodoCloudController.shared.historyItems.chain().do({ [weak self] event in
            switch event {
            case .all:
                self?.tableView.reloadData()
            case .inserted(_, let index):
                self?.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .none)
            default:
                break
            }
        }).sync()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.historyItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = self.historyItems[indexPath.row].name
        return cell
    }
}

extension HistoryViewController {
    func addCell(at row: Int) {
        self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
}
