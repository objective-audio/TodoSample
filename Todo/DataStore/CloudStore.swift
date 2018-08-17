//
//  CloudStore.swift
//  Todo
//
//  Created by yasoshima on 2018/06/28.
//  Copyright © 2018年 Yuki Yasoshima. All rights reserved.
//

import Foundation
import FirebaseFirestore

class CloudStore: DataStoreGateway {
    func addTodoItem(name: String, completion: @escaping (Result<TodoItem>) -> Void) {
        var ref: DocumentReference? = nil
        let data = TodoItemTranslator.newFirebaseData(name: name)
        
        ref = Firestore.firestore().collection("todo_items").addDocument(data: data) { err in
            if let err = err {
                completion(.failed(err))
            } else if let item = TodoItemTranslator.item(from: data, documentID: ref!.documentID) {
                completion(.success(item))
            } else {
                fatalError()
            }
        }
    }
    
    func delete(todoItem: TodoItem, completion: @escaping (Result<Void>) -> Void) {
        self.editTodoItem(documentID: todoItem.documentID, data: TodoItemTranslator.firebaseData(from: todoItem, isDeleted: true)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failed(let err):
                completion(.failed(err))
            }
        }
    }
    
    func toggle(todoItem: TodoItem, completion: @escaping (Result<TodoItem>) -> Void) {
        self.editTodoItem(documentID: todoItem.documentID, data: TodoItemTranslator.firebaseData(from: todoItem, toggleCompleted: true), completion: completion)
    }
    
    private func editTodoItem(documentID: String, data: [String: Any], completion: @escaping (Result<TodoItem>) -> Void) {
        Firestore.firestore().collection("todo_items").document(documentID).setData(data) { err in
            if let err = err {
                completion(.failed(err))
            } else if let item = TodoItemTranslator.item(from: data, documentID: documentID) {
                completion(.success(item))
            } else {
                fatalError()
            }
        }
    }
    
    func todoItems(completion: @escaping (Result<[TodoItem]>) -> Void) {
        Firestore.firestore().collection("todo_items").whereField("is_deleted", isEqualTo: false).order(by: "created_at", descending: true).getDocuments() { (querySnapshot, err) in
            if let err = err {
                completion(.failed(err))
            } else if let querySnapshot = querySnapshot {
                let items = querySnapshot.documents.compactMap { TodoItemTranslator.item(from: $0.data(), documentID: $0.documentID) }
                completion(.success(items))
            } else {
                completion(.success([]))
            }
        }
    }
    
    func addHistoryItem(from todoItem: TodoItem, completion: @escaping (Result<HistoryItem>) -> Void) {
        var ref: DocumentReference? = nil
        let data = HistoryItemTranslator.newFirebaseData(todoItem: todoItem)
        
        ref = Firestore.firestore().collection("history_items").addDocument(data: data) { err in
            if let err = err {
                completion(.failed(err))
            } else if let item = HistoryItemTranslator.item(from: data, documentID: ref!.documentID) {
                completion(.success(item))
            } else {
                fatalError()
            }
        }
    }
    
    func historyItems(completion: @escaping (Result<[HistoryItem]>) -> Void) {
        Firestore.firestore().collection("history_items").whereField("is_deleted", isEqualTo: false).order(by: "completed_at", descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                completion(.failed(err))
            } else if let querySnapshot = querySnapshot {
                let items = querySnapshot.documents.compactMap { HistoryItemTranslator.item(from: $0.data(), documentID: $0.documentID) }
                completion(.success(items))
            } else {
                completion(.success([]))
            }
        }
    }
}
