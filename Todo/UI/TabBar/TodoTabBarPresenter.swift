//
//  TodoTabBarPresenter.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

class TodoTabBarPresenter {
    var port: TodoOutputPort?
    
    init(useCase: TodoOutputPort) {
        self.port = useCase
    }
    
    var isConnecting: ImmutableHolder<Bool> {
        return self.port?.isConnecting ?? Empty.boolHolder
    }
}
