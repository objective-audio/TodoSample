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
    
    let presenter = TodoAddingPresenter(outputPort: AppManager.shared.todoUseCase)
    let controller = TodoAddingController(inputPort: AppManager.shared.todoUseCase)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.pool += self.presenter.todoItemInsertedNotifier.chain().do({ [weak self] _ in
            self?.endEditing(true)
        }).end()
        
        self.pool += self.presenter.addingName.chain().do({ [weak self] name in
            self?.nameTextField.text = name
        }).sync()
        
        self.pool += self.presenter.canAddTodoItem.chain().do({ [weak self] canAdd in
            self?.addButton.isEnabled = canAdd
        }).sync()
        
        self.nameAlias = NotificationAlias(Notification.Name.UITextFieldTextDidChange, object: self.nameTextField)
        
        self.pool += self.nameAlias.chain().do({ [weak self] event in
            self?.controller.addingNameChanged(self?.nameTextField.text)
        }).end()
    }

    @IBAction func add(sender: UIButton) {
        if let name = self.nameTextField.text {
            self.controller.addTodoItem(name: name)
        }
    }
}

extension TodoAddingCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        
        if let name = textField.text {
            self.controller.addTodoItem(name: name)
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        self.controller.addingNameChanged(textField.text)
        self.endEditing(true)
        
        return false
    }
}
