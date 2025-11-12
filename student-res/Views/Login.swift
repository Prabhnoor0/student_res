//
//  Login.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI

@MainActor
final class loginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private let allowedEmails: Set<String> = [
        "prabhnooorkaur11@gmail.com"
    ]
    
    private let allowedDomains: Set<String> = [
        "@iiitl.ac.in"
    ]
    
    func loginn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email or password is empty"
            throw NSError(domain: "ValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email or password is empty"])
        }
        
        let emailLowercased = email.lowercased()
        
        let isAllowedEmail = allowedEmails.contains(emailLowercased)
        
        let isAllowedDomain = allowedDomains.contains { domain in
            emailLowercased.hasSuffix(domain.lowercased())
        }
        
        guard isAllowedEmail || isAllowedDomain else {
            errorMessage = "This email address is not authorized to access the app"
            throw NSError(domain: "ValidationError", code: 403, userInfo: [NSLocalizedDescriptionKey: "This email address is not authorized to access the app"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let getReturnedUser = try await AuthenticationManager.shared.loginUser(email: email, password: password)
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
}

struct Login: View {
    @StateObject var viewmodel = loginViewModel()
    @State var navigate: Bool = false
    @State var showErrorAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                VStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        textfieldview(
                            data2: $viewmodel.email,
                            data: "Enter your email"
                        )
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        securefieldview(
                            data2: $viewmodel.password,
                            data: "Enter your password"
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            Task {
                                await performLogin()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    Task {
                        await performLogin()
                    }
                }) {
                    HStack {
                        if viewmodel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewmodel.isLoading || viewmodel.email.isEmpty || viewmodel.password.isEmpty)
                .opacity((viewmodel.isLoading || viewmodel.email.isEmpty || viewmodel.password.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Use your @iiitl.ac.in email or authorized email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 20)
        }
        .navigationDestination(isPresented: $navigate) {
            MainHomePage()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(viewmodel.errorMessage.isEmpty ? "An error occurred" : viewmodel.errorMessage)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func performLogin() async {
        do {
            try await viewmodel.loginn()
            navigate = true
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        } catch {
            viewmodel.errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        Login()
    }
}
