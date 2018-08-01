//
//  TodoAddingCell.swift
//  Todo
//
//  Created by yasoshima on 2018/07/04.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit
import Chaining

class TodoAddingCell: UITableViewCell {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!

    var nameAlias: NotificationAlias!
    var pool = ObserverPool()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.nameAlias = NotificationAlias(Notification.Name.UITextFieldTextDidChange, object: self.nameTextField)
        
        self.pool += TodoCloudController.shared.todoItems.chain().do({ [weak self] event in
            switch event {
            case .inserted:
                self?.endEditing(true)
            default:
                // 何もしない
                break
            }
        }).sync()
        
        self.pool += TodoCloudController.shared.addingName.chain().do({ [weak self] name in
            self?.nameTextField.text = name
        }).sync()
        
        self.pool += TodoCloudController.shared.canAddTodoItem.chain().do({ [weak self] canAdd in
            self?.addButton.isEnabled = canAdd
        }).sync()
        
        self.pool += self.nameAlias.chain().do({ [weak self] event in
            TodoCloudController.shared.addingNameChanged(self?.nameTextField.text)
        }).end()
    }

    @IBAction func add(sender: UIButton) {
        if let name = self.nameTextField.text {
            TodoCloudController.shared.addTodoItem(name: name)
        }
    }
}

extension TodoAddingCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        
        if let name = textField.text {
            TodoCloudController.shared.addTodoItem(name: name)
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        TodoCloudController.shared.addingNameChanged(textField.text)
        self.endEditing(true)
        
        return false
    }
}
