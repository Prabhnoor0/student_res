//
//  YouTubeLinksView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI

struct YouTubeLinksView: View {
    @State private var links: [YouTubeLink] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedSemester: String? = nil
    @State private var userSemester: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if !userSemester.isEmpty {
                            Button(action: {
                                selectedSemester = userSemester
                                fetchLinks()
                            }) {
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text("My Sem \(userSemester)")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSemester == userSemester ? Color.red : Color(.systemGray5))
                                .foregroundColor(selectedSemester == userSemester ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                        
                        ForEach(["1", "2", "3", "4", "5", "6", "7", "8"], id: \.self) { sem in
                            if sem != userSemester {
                                Button(action: {
                                    selectedSemester = sem
                                    fetchLinks()
                                }) {
                                    Text("Sem \(sem)")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedSemester == sem ? Color.red : Color(.systemGray5))
                                        .foregroundColor(selectedSemester == sem ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search videos by title, subject...", text: $searchText)
                        .onChange(of: searchText) { _, _ in
                            fetchLinks()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            fetchLinks()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Links List
                if isLoading {
                    Spacer()
                    ProgressView("Loading videos...")
                    Spacer()
                } else if links.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No videos available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(links) { link in
                            YouTubeLinkRowView(link: link)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("YouTube Videos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddYouTubeLinkView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                loadUserSemester()
            }
        }
    }
    
    private func loadUserSemester() {
        UserService.shared.getsemester { sem in
            userSemester = sem ?? ""
            if selectedSemester == nil {
                selectedSemester = userSemester.isEmpty ? nil : userSemester
            }
            fetchLinks()
        }
    }
    
    private func fetchLinks() {
        isLoading = true
        let searchQuery = searchText.isEmpty ? nil : searchText
        let semesterToUse = selectedSemester ?? userSemester
        YouTubeLinkService.shared.fetchYouTubeLinks(semester: semesterToUse.isEmpty ? nil : semesterToUse, searchQuery: searchQuery) { fetchedLinks in
            links = fetchedLinks
            isLoading = false
        }
    }
}

struct YouTubeLinkRowView: View {
    let link: YouTubeLink
    
    var body: some View {
        Button(action: {
            openYouTubeLink(url: link.url)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subject = link.subject, !subject.isEmpty {
                        Text(subject)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let description = link.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Label("Sem \(link.semester)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private func openYouTubeLink(url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    YouTubeLinksView()
}

