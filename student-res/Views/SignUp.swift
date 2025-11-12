//
//  SignUp.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI

@MainActor
final class signupviewmodel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmpassword: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    var passwordStrength: PasswordStrength {
        if password.isEmpty { return .none }
        if password.count < 6 { return .weak }
        if password.count < 8 { return .medium }
        if password.count >= 8 && containsSpecialChars { return .strong }
        return .medium
    }
    
    var containsSpecialChars: Bool {
        password.range(of: ".*[^A-Za-z0-9].*", options: .regularExpression) != nil
    }
    
    var passwordsMatch: Bool {
        !password.isEmpty && !confirmpassword.isEmpty && password == confirmpassword
    }
    
    enum PasswordStrength {
        case none, weak, medium, strong
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .none: return ""
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
    
    func signupp() async throws {
        guard !email.isEmpty, !password.isEmpty, !confirmpassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            throw NSError(domain: "ValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please fill in all fields"])
        }
        
        let isIIITL = email.hasSuffix("@iiitl.ac.in")
        let isMainAdmin = email == "prabhnooorkaur11@gmail.com"
        
        guard isIIITL || isMainAdmin else {
            errorMessage = "Only @iiitl.ac.in email addresses are allowed"
            throw NSError(domain: "ValidationError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Only @iiitl.ac.in email addresses are allowed"])
        }
        
        guard password == confirmpassword else {
            errorMessage = "Passwords do not match"
            throw NSError(domain: "ValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"])
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            throw NSError(domain: "ValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
}

struct SignUp: View {
    @StateObject var viewmodel = signupviewmodel()
    @State private var navigate = false
    @State var showErrorAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Join Student Resources")
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
                            data: "Create a password"
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                        if !viewmodel.password.isEmpty {
                            HStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(viewmodel.passwordStrength.color)
                                    .frame(height: 4)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 4)
                            
                            HStack {
                                Text(viewmodel.passwordStrength.text)
                                    .font(.caption)
                                    .foregroundColor(viewmodel.passwordStrength.color)
                                Spacer()
                                if viewmodel.password.count < 6 {
                                    Text("At least 6 characters")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        securefieldview(
                            data2: $viewmodel.confirmpassword,
                            data: "Confirm your password"
                        )
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit {
                            Task {
                                await performSignup()
                            }
                        }
                        
                        if !viewmodel.confirmpassword.isEmpty {
                            HStack {
                                Image(systemName: viewmodel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewmodel.passwordsMatch ? .green : .red)
                                    .font(.caption)
                                Text(viewmodel.passwordsMatch ? "Passwords match" : "Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(viewmodel.passwordsMatch ? .green : .red)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    Task {
                        await performSignup()
                    }
                }) {
                    HStack {
                        if viewmodel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewmodel.isLoading || viewmodel.email.isEmpty || viewmodel.password.isEmpty || viewmodel.confirmpassword.isEmpty || !viewmodel.passwordsMatch)
                .opacity((viewmodel.isLoading || viewmodel.email.isEmpty || viewmodel.password.isEmpty || viewmodel.confirmpassword.isEmpty || !viewmodel.passwordsMatch) ? 0.6 : 1.0)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.purple)
                    Text("Use your @iiitl.ac.in email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 20)
        }
        .navigationDestination(isPresented: $navigate) {
            DetailsPage()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(viewmodel.errorMessage.isEmpty ? "An error occurred" : viewmodel.errorMessage)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func performSignup() async {
        do {
            try await viewmodel.signupp()
            navigate = true
        } catch {
            viewmodel.errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
