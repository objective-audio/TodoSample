//
//  TodoTabBarController.swift
//  Todo
//
//  Created by yasoshima on 2018/07/02.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit

class TodoTabBarController: UITabBarController {
    private let receiver = NotificationReceiver()
    private var overlapView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.receiver.add(sender: TodoCloudController.shared.eventSender) { [weak self] event in
            switch event {
            case .todoItemsLoadError, .todoItemEditError, .todoItemRemoveError, .historyItemsLoadError:
                self?.showAlert()
            case .beginConnection:
                self?.showIndicator()
            case .endConnection:
                self?.hideIndicator()
                
            default:
                break
            }
        }
    }

    private func showAlert() {
        let alert = UIAlertController(title: "通信エラー", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showIndicator() {
        let overlapView = UIView(frame: self.view.bounds)
        overlapView.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        self.view.addSubview(overlapView)
        self.overlapView = overlapView
    }
    
    private func hideIndicator() {
        if let overlapView = self.overlapView {
            overlapView.removeFromSuperview()
            self.overlapView = nil
        }
    }
}
