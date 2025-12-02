//
//  NextPage.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI

enum auth {
    case login
    case signup
}

struct NextPage: View {
    @State private var authtype: auth = .login
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Auth Type", selection: $authtype) {
                Text("Log In").tag(auth.login)
                Text("Sign Up").tag(auth.signup)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            if authtype == .login {
                Login()
            } else {
                SignUp()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
    


#Preview {
    NextPage()
}

