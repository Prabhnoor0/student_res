//
//  QuizQuestion.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 29/12/25.
//

import Foundation

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
}

