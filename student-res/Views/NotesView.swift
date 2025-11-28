//
//  NotesView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI

struct NotesView: View {
    @State private var notes: [Note] = []
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
                                fetchNotes()
                            }) {
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text("My Sem \(userSemester)")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSemester == userSemester ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedSemester == userSemester ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                        
                        ForEach(["1", "2", "3", "4", "5", "6", "7", "8"], id: \.self) { sem in
                            if sem != userSemester {
                                Button(action: {
                                    selectedSemester = sem
                                    fetchNotes()
                                }) {
                                    Text("Sem \(sem)")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedSemester == sem ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedSemester == sem ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search notes by name or subject...", text: $searchText)
                        .onChange(of: searchText) { _, _ in
                            fetchNotes()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            fetchNotes()
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
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading notes...")
                    Spacer()
                } else if notes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No notes available")
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
                        ForEach(notes) { note in
                            NoteRowView(note: note)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink(destination: SubmitNoteForReviewView()) {
                            Label("Submit Note for Review", systemImage: "square.and.arrow.up")
                        }
                        NavigationLink(destination: WriteNotesView()) {
                            Label("My Personal Notes", systemImage: "note.text")
                        }
                    } label: {
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
            fetchNotes()
        }
    }
    
    private func fetchNotes() {
        isLoading = true
        let searchQuery = searchText.isEmpty ? nil : searchText
        let semesterToUse = selectedSemester ?? userSemester
        NotesService.shared.fetchNotes(semester: semesterToUse.isEmpty ? nil : semesterToUse, searchQuery: searchQuery) { fetchedNotes in
            notes = fetchedNotes
            isLoading = false
        }
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        Button(action: {
            openPDF(url: note.url)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subject = note.subject, !subject.isEmpty {
                        Text(subject)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Sem \(note.semester)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let date = note.uploadedDate {
                            Text("• \(date, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private func openPDF(url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NotesView()
}

