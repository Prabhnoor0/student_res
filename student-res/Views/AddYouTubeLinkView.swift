//
//  AddYouTubeLinkView.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 29/12/25.
//

import SwiftUI

struct AddYouTubeLinkView: View {
    @State private var title = ""
    @State private var url = ""
    @State private var selectedSemester = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    let semesters = ["1", "2", "3", "4", "5", "6", "7", "8"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Video Details")) {
                    TextField("Video Title", text: $title)
                    
                    TextField("YouTube URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Picker("Semester", selection: $selectedSemester) {
                        Text("Select Semester").tag("")
                        ForEach(semesters, id: \.self) { sem in
                            Text("Semester \(sem)").tag(sem)
                        }
                    }
                    
                    TextField("Subject (Optional)", text: $subject)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(footer: Text("Your link will be reviewed by an admin before being made visible to everyone.")) {
                    Button(action: submitLink) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Submit for Review")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(title.isEmpty || url.isEmpty || selectedSemester.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add YouTube Link")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your link has been submitted for review. It will be visible to everyone once approved by an admin.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitLink() {
        guard !title.isEmpty, !url.isEmpty, !selectedSemester.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showErrorAlert = true
            return
        }
        
        guard url.contains("youtube.com") || url.contains("youtu.be") else {
            errorMessage = "Please enter a valid YouTube URL"
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        
        YouTubeLinkService.shared.submitYouTubeLink(
            title: title,
            url: url,
            semester: selectedSemester,
            subject: subject.isEmpty ? nil : subject,
            description: description.isEmpty ? nil : description
        ) { error in
            isSubmitting = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                showSuccessAlert = true
                title = ""
                url = ""
                selectedSemester = ""
                subject = ""
                description = ""
            }
        }
    }
}

#Preview {
    AddYouTubeLinkView()
}

