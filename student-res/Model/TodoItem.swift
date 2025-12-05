//
//  TodoItem.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 29/12/25.
//

import Foundation

struct TodoItem: Identifiable, Codable {
    var id: String
    var title: String
    var description: String?
    var isCompleted: Bool
    var dueDate: Date?
    var createdAt: Date
}

