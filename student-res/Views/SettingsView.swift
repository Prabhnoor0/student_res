//
//  SettingsView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @State private var showLogoutAlert = false
    @State private var navigateToLogin = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Profile Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Support")) {
                    Link(destination: URL(string: "mailto:support@studentres.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Contact Support")
                        }
                    }
                    
                    Link(destination: URL(string: "https://studentres.com/help")!) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("Help & FAQ")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .fullScreenCover(isPresented: $navigateToLogin) {
                NextPage()
            }
            .onChange(of: navigateToLogin) { _, newValue in
                if newValue {
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
                }
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            navigateToLogin = true
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}

