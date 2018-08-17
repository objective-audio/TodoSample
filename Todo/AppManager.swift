//
//  ApplicationManager.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

class AppManager {
    static let shared = AppManager()
    
    let dataStore: DataStoreGateway = CloudStore()
    let todoUseCase: TodoUseCase
    
    init() {
        self.todoUseCase = TodoUseCase(dataStore: self.dataStore)
        self.todoUseCase.firstSetup()
    }
}
