//
//  AdminDashboardView.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 29/12/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var notesSubmissions: [NoteSubmission] = []
    @State private var youtubeSubmissions: [YouTubeLinkSubmission] = []
    @State private var questionPaperSubmissions: [QuestionPaperSubmission] = []
    @State private var isLoading = true
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Notes Submissions
            SubmissionsListView(
                title: "Notes Submissions",
                submissions: notesSubmissions.map { AnySubmission.note($0) },
                isLoading: isLoading,
                onRefresh: loadAllSubmissions,
                onApprove: { submission in
                    approveNote(submission)
                },
                onReject: { submission in
                    rejectNote(submission)
                }
            )
            .tabItem {
                Label("Notes", systemImage: "book.fill")
            }
            .tag(0)
            
            // YouTube Links Submissions
            SubmissionsListView(
                title: "YouTube Links",
                submissions: youtubeSubmissions.map { AnySubmission.youtube($0) },
                isLoading: isLoading,
                onRefresh: loadAllSubmissions,
                onApprove: { submission in
                    approveYouTubeLink(submission)
                },
                onReject: { submission in
                    rejectYouTubeLink(submission)
                }
            )
            .tabItem {
                Label("YouTube", systemImage: "play.rectangle.fill")
            }
            .tag(1)
            
            // Question Paper Submissions
            SubmissionsListView(
                title: "Question Papers",
                submissions: questionPaperSubmissions.map { AnySubmission.questionPaper($0) },
                isLoading: isLoading,
                onRefresh: loadAllSubmissions,
                onApprove: { submission in
                    approveQuestionPaper(submission)
                },
                onReject: { submission in
                    rejectQuestionPaper(submission)
                }
            )
            .tabItem {
                Label("Papers", systemImage: "doc.text.fill")
            }
            .tag(2)
        }
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadAllSubmissions()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadAllSubmissions() {
        isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        loadNotesSubmissions {
            group.leave()
        }
    
        group.enter()
        loadYouTubeSubmissions {
            group.leave()
        }
    
        group.enter()
        loadQuestionPaperSubmissions {
            group.leave()
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func loadNotesSubmissions(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("NotesSubmissions")
            .whereField("status", isEqualTo: "pending")
            .order(by: "uploadedDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading notes: \(error)")
                    completion()
                    return
                }
                
                self.notesSubmissions = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return NoteSubmission(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        url: data["url"] as? String ?? "",
                        semester: data["semester"] as? String ?? "",
                        subject: data["subject"] as? String,
                        uploadedBy: data["uploadedBy"] as? String ?? "",
                        uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "pending"
                    )
                } ?? []
                completion()
            }
    }
    
    private func loadYouTubeSubmissions(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("YouTubeLinkSubmissions")
            .whereField("status", isEqualTo: "pending")
            .order(by: "uploadedDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading YouTube links: \(error)")
                    completion()
                    return
                }
                
                self.youtubeSubmissions = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return YouTubeLinkSubmission(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        url: data["url"] as? String ?? "",
                        semester: data["semester"] as? String ?? "",
                        subject: data["subject"] as? String,
                        description: data["description"] as? String,
                        uploadedBy: data["uploadedBy"] as? String ?? "",
                        uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "pending"
                    )
                } ?? []
                completion()
            }
    }
    
    private func loadQuestionPaperSubmissions(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("QuestionPaperSubmissions")
            .whereField("status", isEqualTo: "pending")
            .order(by: "uploadedDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading question papers: \(error)")
                    completion()
                    return
                }
                
                self.questionPaperSubmissions = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return QuestionPaperSubmission(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        url: data["url"] as? String ?? "",
                        semester: data["semester"] as? String ?? "",
                        subject: data["subject"] as? String,
                        uploadedBy: data["uploadedBy"] as? String ?? "",
                        uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "pending"
                    )
                } ?? []
                completion()
            }
    }
    
    private func approveNote(_ submission: AnySubmission) {
        guard case .note(let noteSubmission) = submission else { return }
        AdminService.shared.approveNote(submission: noteSubmission) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                loadAllSubmissions()
            }
        }
    }
    
    private func rejectNote(_ submission: AnySubmission) {
        guard case .note(let noteSubmission) = submission else { return }
        AdminService.shared.rejectNote(submissionId: noteSubmission.id, collection: "NotesSubmissions") { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                loadAllSubmissions()
            }
        }
    }
    
    private func approveYouTubeLink(_ submission: AnySubmission) {
        guard case .youtube(let youtubeSubmission) = submission else { return }
        AdminService.shared.approveYouTubeLink(submission: youtubeSubmission) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                loadAllSubmissions()
            }
        }
    }
    
    private func rejectYouTubeLink(_ submission: AnySubmission) {
        guard case .youtube(let youtubeSubmission) = submission else { return }
        AdminService.shared.rejectNote(submissionId: youtubeSubmission.id, collection: "YouTubeLinkSubmissions") { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                loadAllSubmissions()
            }
        }
    }
    
    private func approveQuestionPaper(_ submission: AnySubmission) {
        guard case .questionPaper(let paperSubmission) = submission else { return }
        AdminService.shared.approveQuestionPaper(submission: paperSubmission) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                loadAllSubmissions()
            }
        }
    }
    
    private func rejectQuestionPaper(_ submission: AnySubmission) {
        guard case .questionPaper(let paperSubmission) = submission else { return }
        AdminService.shared.rejectNote(submissionId: paperSubmission.id, collection: "QuestionPaperSubmissions") { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                loadAllSubmissions()
            }
        }
    }
}

enum AnySubmission: Identifiable {
    case note(NoteSubmission)
    case youtube(YouTubeLinkSubmission)
    case questionPaper(QuestionPaperSubmission)
    
    var id: String {
        switch self {
        case .note(let s): return s.id
        case .youtube(let s): return s.id
        case .questionPaper(let s): return s.id
        }
    }
    
    var title: String {
        switch self {
        case .note(let s): return s.name
        case .youtube(let s): return s.title
        case .questionPaper(let s): return s.name
        }
    }
    
    var semester: String {
        switch self {
        case .note(let s): return s.semester
        case .youtube(let s): return s.semester
        case .questionPaper(let s): return s.semester
        }
    }
}

struct SubmissionsListView: View {
    let title: String
    let submissions: [AnySubmission]
    let isLoading: Bool
    let onRefresh: () -> Void
    let onApprove: (AnySubmission) -> Void
    let onReject: (AnySubmission) -> Void
    
    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView("Loading submissions...")
            } else if submissions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No pending submissions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(submissions) { submission in
                        SubmissionRowView(
                            submission: submission,
                            onApprove: { onApprove(submission) },
                            onReject: { onReject(submission) }
                        )
                    }
                }
            }
        }
        .navigationTitle(title)
        .refreshable {
            onRefresh()
        }
    }
}

struct SubmissionRowView: View {
    let submission: AnySubmission
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(submission.title)
                .font(.headline)
            
            Text("Semester \(submission.semester)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: onApprove) {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button(action: onReject) {
                    Label("Reject", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

struct YouTubeLinkSubmission: Identifiable {
    let id: String
    let title: String
    let url: String
    let semester: String
    let subject: String?
    let description: String?
    let uploadedBy: String
    let uploadedDate: Date
    let status: String
}

struct QuestionPaperSubmission: Identifiable {
    let id: String
    let name: String
    let url: String
    let semester: String
    let subject: String?
    let uploadedBy: String
    let uploadedDate: Date
    let status: String
}

#Preview {
    AdminDashboardView()
}

