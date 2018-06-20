//
//  AppController.swift
//  Todo
//
//  Created by yasoshima on 2018/06/15.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class AppController {
    static let shared = AppController()
    
    let todoController = TodoController()
    
    init() {}
}
