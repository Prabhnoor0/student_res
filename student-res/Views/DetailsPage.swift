//
//  DetailsPage.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI

@MainActor
final class DetailsPageViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var enrollno: String = ""
    @Published var semselection: String?
    @Published var branchselection: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    let semesters = ["1", "2", "3", "4", "5", "6", "7", "8"]
    let branches = ["CS", "CSAI", "CSB", "IT"]
    
    var isFormValid: Bool {
        !name.isEmpty && !enrollno.isEmpty && semselection != nil && branchselection != nil
    }
    
    func SaveUserInfo() async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let user = try? AuthenticationManager.shared.getauthenticateduser() else {
                errorMessage = "User not found. Please try logging in again."
                return
            }
            
            let userData: [String: Any] = [
                "name": name,
                "enrollmentnumber": enrollno,
                "semester": semselection ?? "",
                "branch": branchselection ?? ""
            ]
            
            try await UserManager.shared.saveUserData(userId: user.uid, data: userData)
        } catch {
            print("Error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}

struct DetailsPage: View {
    @StateObject var viewmodel = DetailsPageViewModel()
    @State var navigate: Bool = false
    @State var showErrorAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, enrollment
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
               
                VStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Complete Your Profile")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Tell us a bit about yourself")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                
                VStack(spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        textfieldview(
                            data2: $viewmodel.name,
                            data: "Enter your full name"
                        )
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .enrollment
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enrollment Number")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        textfieldview(
                            data2: $viewmodel.enrollno,
                            data: "Enter your enrollment number"
                        )
                        .focused($focusedField, equals: .enrollment)
                        .keyboardType(.default)
                        .submitLabel(.next)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Semester")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Menu {
                            ForEach(viewmodel.semesters, id: \.self) { sem in
                                Button(action: {
                                    viewmodel.semselection = sem
                                }) {
                                    HStack {
                                        Text("Semester \(sem)")
                                        if viewmodel.semselection == sem {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewmodel.semselection != nil ? "Semester \(viewmodel.semselection!)" : "Select Semester")
                                    .foregroundColor(viewmodel.semselection == nil ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Branch")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Menu {
                            ForEach(viewmodel.branches, id: \.self) { branch in
                                Button(action: {
                                    viewmodel.branchselection = branch
                                }) {
                                    HStack {
                                        Text(branch)
                                        if viewmodel.branchselection == branch {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewmodel.branchselection ?? "Select Branch")
                                    .foregroundColor(viewmodel.branchselection == nil ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    Task {
                        await viewmodel.SaveUserInfo()
                        if viewmodel.errorMessage.isEmpty {
                            navigate = true
                        } else {
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        if viewmodel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewmodel.isLoading || !viewmodel.isFormValid)
                .opacity((viewmodel.isLoading || !viewmodel.isFormValid) ? 0.6 : 1.0)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("This information helps us personalize your experience")
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
            Button("OK") {
                viewmodel.errorMessage = ""
            }
        } message: {
            Text(viewmodel.errorMessage.isEmpty ? "An error occurred" : viewmodel.errorMessage)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        DetailsPage()
    }
}
