//
//  student_resApp.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct student_resApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentRootView()
        }
    }
}

struct ContentRootView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                MainHomePage()
            } else {
                HomePage()
            }
        }
        .onAppear {
            checkAuthentication()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
            isAuthenticated = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
            isAuthenticated = false
        }
    }
    
    private func checkAuthentication() {
        isAuthenticated = Auth.auth().currentUser != nil
    }
}
