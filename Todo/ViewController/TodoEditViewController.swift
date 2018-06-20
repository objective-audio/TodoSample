//
//  TodoEditViewController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

class TodoEditViewController: UIViewController {
    @IBOutlet var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.nameTextField.becomeFirstResponder()
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        if let name = self.nameTextField.text, !name.isEmpty {
            TodoController.shared.addTodoItem(name: name)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
