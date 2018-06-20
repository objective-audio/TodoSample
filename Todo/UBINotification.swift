//
//  UBINotification.swift
//
//  Created by Yuki Yasoshima on 2017/06/06.
//  Copyright © 2017 Ubiregi inc. All rights reserved.
//

import Foundation

protocol NotificationSendable {
    associatedtype Context
    static var notificationName: Notification.Name { get }
    static var userInfoKey: String { get }

    func post(context: Context)
}

extension NotificationSendable {
    static var userInfoKey: String { return "context" }

    func post(context: Context) {
        NotificationCenter.default.post(name: Self.notificationName, object: self, userInfo: [Self.userInfoKey: context])
    }
}

class NotificationReceiver {
    private class Container {
        let name: Notification.Name
        let observer: NSObjectProtocol

        init(name: Notification.Name, object: Any?, block: @escaping (_ notification: Notification) -> Void) {
            self.name = name
            self.observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: nil, using: block)
        }

        deinit {
            NotificationCenter.default.removeObserver(self.observer)
        }
    }

    private var containers: [Container] = []

    func add<T: NotificationSendable>(sender: T, using block: @escaping (T.Context) -> Void) {
        self.containers.append(Container(name: T.notificationName, object: sender) { (notification) in
            if let info = notification.userInfo as? [String: Any] {
                if let context = info[T.userInfoKey] as? T.Context {
                    block(context)
                }
            }
        })
    }

    func remove<T: NotificationSendable>(sender: T) {
        self.remove(name: T.notificationName)
    }

    func remove(name: Notification.Name) {
        self.containers = self.containers.filter { $0.name != name }
    }

    deinit {
        self.containers.removeAll()
    }
}
