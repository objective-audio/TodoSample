//
//  Empty.swift
//  Todo
//
//  Created by yasoshima on 2018/08/16.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

struct Empty {
    static let boolHolder: ImmutableHolder<Bool> = Holder(false)
    static let optStringHolder: ImmutableHolder<String?> = Holder(nil)
    static let todoItemArrayHolder: ImmutableArrayHolder<Holder<TodoItem>> = ArrayHolder<Holder<TodoItem>>()
    static let historyItemArrayHolder: ImmutableArrayHolder<HistoryItem> = ArrayHolder<HistoryItem>()
}
