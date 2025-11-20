//
//  MainHomePage.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import FirebaseAuth

struct MainHomePage: View {
    @State private var selectedTab = 0
    @State private var userSemester: String = ""
    @State private var userName: String = ""
    @State private var userProfileImageURL: String? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeTabView(userSemester: $userSemester, userName: $userName, userProfileImageURL: $userProfileImageURL)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Question Papers Tab
            QuestionPapers()
                .tabItem {
                    Label("Question Papers", systemImage: "doc.text.fill")
                }
                .tag(1)
            
            // Notes Tab
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "book.fill")
                }
                .tag(2)
            
            // YouTube Links Tab
            YouTubeLinksView()
                .tabItem {
                    Label("Videos", systemImage: "play.rectangle.fill")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView(userName: $userName, userProfileImageURL: $userProfileImageURL)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .onAppear {
            loadUserData()
            UserService.shared.checkAndIncrementSemester { didIncrement in
                if didIncrement {
                    loadUserData()
                }
            }
        }
    }
    
    private func loadUserData() {
        UserService.shared.getsemester { sem in
            userSemester = sem ?? ""
        }
        
        guard let user = Auth.auth().currentUser else { return }
        UserService.shared.fetchUserData(uid: user.uid) { data in
            if let data = data {
                userName = data["name"] as? String ?? ""
                userProfileImageURL = data["profileImageURL"] as? String
            }
        }
    }
}

struct HomeTabView: View {
    @Binding var userSemester: String
    @Binding var userName: String
    @Binding var userProfileImageURL: String?
    @State private var navigateToWriteNotes = false
    @State private var navigateToAIQuiz = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let imageURL = userProfileImageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(userName.isEmpty ? "Student" : userName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        
                        if !userSemester.isEmpty {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Semester \(userSemester)")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        NavigationLink(destination: WriteNotesView()) {
                            FeatureCard(
                                title: "Write Notes",
                                icon: "pencil.and.outline",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: AIQuizGeneratorView()) {
                            FeatureCard(
                                title: "AI Quiz Generator",
                                icon: "brain.head.profile",
                                color: .purple
                            )
                        }
                        
                        NavigationLink(destination:     QuestionPapers()) {
                            FeatureCard(
                                title: "Question Papers",
                                icon: "doc.text.fill",
                                color: .green
                            )
                        }
                        
                        NavigationLink(destination: NotesView()) {
                            FeatureCard(
                                title: "View Notes",
                                icon: "book.fill",
                                color: .orange
                            )
                        }
                        
                        NavigationLink(destination: YouTubeLinksView()) {
                            FeatureCard(
                                title: "YouTube Links",
                                icon: "play.rectangle.fill",
                                color: .red
                            )
                        }
                        
                        NavigationLink(destination: TodoListView()) {
                            FeatureCard(
                                title: "To-Do List",
                                icon: "checklist",
                                color: .indigo
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Student Resources")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct FeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    MainHomePage()
}

