//
//  Result.swift
//  Todo
//
//  Created by yasoshima on 2018/08/08.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failed(Error)
}
