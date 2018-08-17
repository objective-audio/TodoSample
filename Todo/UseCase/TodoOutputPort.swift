//
//  TodoOutputPort.swift
//  Todo
//
//  Created by yasoshima on 2018/08/09.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

protocol TodoOutputPort: class {
    var todoItems: ImmutableArrayHolder<Holder<TodoItem>> { get }
    var historyItems: ImmutableArrayHolder<HistoryItem> { get }
    var isConnecting: ImmutableHolder<Bool> { get }
    var addingName: ImmutableHolder<String?> { get }
    var canAddTodoItem: ImmutableHolder<Bool> { get }
    var errorNotifier: Notifier<Error> { get }
}
