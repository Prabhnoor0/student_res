//
//  SubmitNoteForReviewView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth

enum NoteInputMethod: String, CaseIterable {
    case url = "Enter URL"
    case upload = "Upload File"
}

struct SubmitNoteForReviewView: View {
    @State private var noteName = ""
    @State private var selectedSemester = ""
    @State private var subject = ""
    @State private var inputMethod: NoteInputMethod = .url
    @State private var pdfURL: String? = nil
    @State private var selectedFile: URL? = nil
    @State private var isUploading = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showFilePicker = false
    @Environment(\.dismiss) var dismiss
    
    let semesters = ["1", "2", "3", "4", "5", "6", "7", "8"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Note Name", text: $noteName)
                    
                    Picker("Semester", selection: $selectedSemester) {
                        Text("Select Semester").tag("")
                        ForEach(semesters, id: \.self) { sem in
                            Text("Semester \(sem)").tag(sem)
                        }
                    }
                    
                    TextField("Subject (Optional)", text: $subject)
                }
                
                Section(header: Text("PDF File")) {
                    Picker("Input Method", selection: $inputMethod) {
                        ForEach(NoteInputMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    if inputMethod == .url {
                        TextField("PDF URL", text: Binding(
                            get: { pdfURL ?? "" },
                            set: { pdfURL = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    } else {
                        Button(action: {
                            showFilePicker = true
                        }) {
                            HStack {
                                if let file = selectedFile {
                                    Image(systemName: "doc.fill")
                                    Text(file.lastPathComponent)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select PDF File")
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                Image(systemName: "folder")
                            }
                        }
                        .fileImporter(
                            isPresented: $showFilePicker,
                            allowedContentTypes: [.pdf],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    selectedFile = url
                                    uploadFileToCloudinary(fileURL: url)
                                }
                            case .failure(let error):
                                errorMessage = "Failed to select file: \(error.localizedDescription)"
                                showErrorAlert = true
                            }
                        }
                        
                        if let file = selectedFile {
                            Text("File selected: \(file.lastPathComponent)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(footer: Text("Your note will be reviewed by an admin before being made visible to everyone.")) {
                    Button(action: submitNote) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Submit for Review")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(noteName.isEmpty || selectedSemester.isEmpty || (inputMethod == .url && pdfURL == nil) || (inputMethod == .upload && selectedFile == nil) || isUploading)
                }
            }
            .navigationTitle("Submit Note")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your note has been submitted for review. It will be visible to everyone once approved by an admin.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func uploadFileToCloudinary(fileURL: URL) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not authenticated"
            showErrorAlert = true
            return
        }
        
        isUploading = true
        guard fileURL.startAccessingSecurityScopedResource() else {
            errorMessage = "Failed to access file"
            showErrorAlert = true
            isUploading = false
            return
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        let folder = "notes/pending/\(user.uid)"
        CloudinaryService.shared.uploadPDF(fileURL: fileURL, folder: folder) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success(let url):
                    self.pdfURL = url
                case .failure(let error):
                    self.errorMessage = "Failed to upload file: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    self.selectedFile = nil
                }
            }
        }
    }
    
    private func submitNote() {
        guard !noteName.isEmpty, !selectedSemester.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showErrorAlert = true
            return
        }
        
        var finalURL: String
        
        if inputMethod == .url {
            guard let url = pdfURL, !url.isEmpty else {
                errorMessage = "Please enter a PDF URL"
                showErrorAlert = true
                return
            }
            finalURL = url
        } else {
            guard let url = pdfURL, !url.isEmpty else {
                errorMessage = "Please wait for file upload to complete or select a file"
                showErrorAlert = true
                return
            }
            finalURL = url
        }
        
        isUploading = true
        
        NotesService.shared.submitNote(
            name: noteName,
            url: finalURL,
            semester: selectedSemester,
            subject: subject.isEmpty ? nil : subject
        ) { error in
            isUploading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } else {
                showSuccessAlert = true
                // Reset form
                noteName = ""
                selectedSemester = ""
                subject = ""
                pdfURL = nil
                selectedFile = nil
                inputMethod = .url
            }
        }
    }
}

#Preview {
    SubmitNoteForReviewView()
}

