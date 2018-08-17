//
//  HistoryPresenter.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Chaining

class HistoryPresenter {
    var outputPort: TodoOutputPort?
    
    init(outputPort: TodoOutputPort) {
        self.outputPort = outputPort
    }
    
    var historyItems: ImmutableArrayHolder<HistoryItem> {
        return self.outputPort?.historyItems ?? Empty.historyItemArrayHolder
    }
}
