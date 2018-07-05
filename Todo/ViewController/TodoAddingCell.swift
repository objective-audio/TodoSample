//
//  TodoAddingCell.swift
//  Todo
//
//  Created by yasoshima on 2018/07/04.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

class TodoAddingCell: UITableViewCell {
    @IBOutlet var nameTextField: UITextField!

    let receiver = NotificationReceiver()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.receiver.add(sender: TodoCloudController.shared.eventSender) { [weak self] event in
            switch event {
            case .todoItemAdded:
                self?.nameTextField.text = nil
            default:
                // 何もしない
                break
            }
        }
    }

    @IBAction func add(sender: UIButton) {
        if let name = self.nameTextField.text, !name.isEmpty {
            TodoCloudController.shared.addTodoItem(name: name)
        }
    }
}
