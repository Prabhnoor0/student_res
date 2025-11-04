//
//  UserManager.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 12/10/25.
//


import FirebaseFirestore

final class UserManager {
    static let shared = UserManager()
    private init(){
    }
    private let db = Firestore.firestore()

    func saveUserData(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).setData(data, merge: true)
    }
}


