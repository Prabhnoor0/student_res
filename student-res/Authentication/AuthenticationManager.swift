//
//  AuthenticationManager.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI
import FirebaseAuth

struct AuthDataResultModel{
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user:User){
        self.uid=user.uid
        self.email=user.email
        self.photoURL=user.photoURL?.absoluteString
    }
}
final class AuthenticationManager{
    
    static let shared = AuthenticationManager()
    
    private init(){}
    
    func getauthenticateduser() throws -> AuthDataResultModel?{
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return AuthDataResultModel(user: user)
    }
    func createUser(email: String, password: String) async throws -> AuthDataResultModel{
      let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    func loginUser(email:String,password:String) async throws ->AuthDataResultModel{
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
          return AuthDataResultModel(user: authDataResult.user)
    }
}
