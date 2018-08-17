//
//  TodoTabBarController.swift
//  Todo
//
//  Created by yasoshima on 2018/07/02.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import UIKit
import Chaining

class TodoTabBarController: UITabBarController {
    private let presenter = TodoTabBarPresenter(useCase: AppManager.shared.todoUseCase)
    
    private var pool = ObserverPool()
    private var overlapView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool += self.presenter.isConnecting.chain().do( { [weak self] isConnecting in
            if isConnecting {
                self?.showIndicator()
            } else {
                self?.hideIndicator()
            }
        }).sync()
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
