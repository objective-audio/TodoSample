//
//  CloudStore.swift
//  Todo
//
//  Created by yasoshima on 2018/06/28.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum Result<T> {
    case success(T)
    case failed(Error)
}

class CloudStore {
    static func addTodoItem(name: String, completion: @escaping (Result<TodoItem>) -> Void) {
        var ref: DocumentReference? = nil
        let data = TodoItem.addingFirebaseData(name: name)
        
        ref = Firestore.firestore().collection("todo_items").addDocument(data: data) { err in
            if let err = err {
                completion(.failed(err))
            } else if let item = TodoItem.item(from: data, documentID: ref!.documentID) {
                completion(.success(item))
            } else {
                fatalError()
            }
        }
    }
    
    static func delete(todoItem: TodoItem, completion: @escaping (Result<Void>) -> Void) {
        self.editTodoItem(documentID: todoItem.documentID, data: todoItem.firebaseData(isDeleted: true)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failed(let err):
                completion(.failed(err))
            }
        }
    }
    
    static func toggle(todoItem: TodoItem, completion: @escaping (Result<TodoItem>) -> Void) {
        self.editTodoItem(documentID: todoItem.documentID, data: todoItem.firebaseData(toggleCompleted: true), completion: completion)
    }
    
    static private func editTodoItem(documentID: String, data: [String: Any], completion: @escaping (Result<TodoItem>) -> Void) {
        Firestore.firestore().collection("todo_items").document(documentID).setData(data) { err in
            if let err = err {
                completion(.failed(err))
            } else if let item = TodoItem.item(from: data, documentID: documentID) {
                completion(.success(item))
            } else {
                fatalError()
            }
        }
    }
    
    static func todoItems(completion: @escaping (Result<[TodoItem]>) -> Void) {
        Firestore.firestore().collection("todo_items").whereField("is_deleted", isEqualTo: false).order(by: "created_at", descending: true).getDocuments() { (querySnapshot, err) in
            if let err = err {
                completion(.failed(err))
            } else if let querySnapshot = querySnapshot {
                let items = querySnapshot.documents.compactMap { TodoItem.item(from: $0.data(), documentID: $0.documentID) }
                completion(.success(items))
            } else {
                completion(.success([]))
            }
        }
    }
    
    static func addHistoryItem(from todoItem: TodoItem, completion: @escaping (Result<HistoryItem>) -> Void) {
        var ref: DocumentReference? = nil
        let data = HistoryItem.addingFirebaseData(todoItem: todoItem)
        
        ref = Firestore.firestore().collection("history_items").addDocument(data: data) { err in
            if let err = err {
                completion(.failed(err))
            } else if let item = HistoryItem.item(from: data, documentID: ref!.documentID) {
                completion(.success(item))
            } else {
                fatalError()
            }
        }
    }
    
    static func historyItems(completion: @escaping (Result<[HistoryItem]>) -> Void) {
        Firestore.firestore().collection("history_items").whereField("is_deleted", isEqualTo: false).order(by: "completed_at", descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                completion(.failed(err))
            } else if let querySnapshot = querySnapshot {
                let items = querySnapshot.documents.compactMap { HistoryItem.item(from: $0.data(), documentID: $0.documentID) }
                completion(.success(items))
            } else {
                completion(.success([]))
            }
        }
    }
}
