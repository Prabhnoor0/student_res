//
//  AdminService.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class AdminService {
    static let shared = AdminService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func approveNote(submission: NoteSubmission, completion: @escaping (Error?) -> Void) {
        let urlToUse = submission.url
        
        if urlToUse.contains("cloudinary.com") {
            addNoteToFirebase(submission: submission, cloudinaryURL: urlToUse, completion: completion)
        } else {
            uploadToCloudinaryAndApprove(
                url: urlToUse,
                fileName: "\(submission.name).pdf",
                folder: "notes/\(submission.semester)",
                submission: submission,
                completion: completion
            )
        }
    }
    
    func approveYouTubeLink(submission: YouTubeLinkSubmission, completion: @escaping (Error?) -> Void) {
        let linkData: [String: Any] = [
            "title": submission.title,
            "url": submission.url,
            "semester": submission.semester,
            "subject": submission.subject ?? "",
            "description": submission.description ?? "",
            "uploadedBy": submission.uploadedBy,
            "uploadedDate": Timestamp(date: submission.uploadedDate),
            "isApproved": true
        ]
        
        let collection = "YouTubeLinks\(submission.semester)"
        db.collection(collection).addDocument(data: linkData) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Update submission status
            self.db.collection("YouTubeLinkSubmissions").document(submission.id).updateData([
                "status": "approved"
            ]) { error in
                completion(error)
            }
        }
    }
    
    func approveQuestionPaper(submission: QuestionPaperSubmission, completion: @escaping (Error?) -> Void) {
        let urlToUse = submission.url
        
        if urlToUse.contains("cloudinary.com") {
            // Already on Cloudinary, use existing URL
            addQuestionPaperToFirebase(submission: submission, cloudinaryURL: urlToUse, completion: completion)
        } else {
            uploadToCloudinaryAndApproveQuestionPaper(
                url: urlToUse,
                fileName: "\(submission.name).pdf",
                folder: "question-papers/\(submission.semester)",
                submission: submission,
                completion: completion
            )
        }
    }
    
    private func uploadToCloudinaryAndApprove(
        url: String,
        fileName: String,
        folder: String,
        submission: NoteSubmission,
        completion: @escaping (Error?) -> Void
    ) {
        guard let fileURL = URL(string: url) else {
            completion(NSError(domain: "AdminError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: fileURL) { data, response, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(NSError(domain: "AdminError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            CloudinaryService.shared.uploadPDFFromData(
                data: data,
                fileName: fileName,
                folder: folder
            ) { result in
                switch result {
                case .success(let cloudinaryURL):
                    
                    self.addNoteToFirebase(submission: submission, cloudinaryURL: cloudinaryURL, completion: completion)
                case .failure(let error):
                    completion(error)
                }
            }
        }.resume()
    }
    
    private func uploadToCloudinaryAndApproveQuestionPaper(
        url: String,
        fileName: String,
        folder: String,
        submission: QuestionPaperSubmission,
        completion: @escaping (Error?) -> Void
    ) {
        guard let fileURL = URL(string: url) else {
            completion(NSError(domain: "AdminError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        URLSession.shared.dataTask(with: fileURL) { data, response, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(NSError(domain: "AdminError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            CloudinaryService.shared.uploadPDFFromData(
                data: data,
                fileName: fileName,
                folder: folder
            ) { result in
                switch result {
                case .success(let cloudinaryURL):
                    self.addQuestionPaperToFirebase(submission: submission, cloudinaryURL: cloudinaryURL, completion: completion)
                case .failure(let error):
                    completion(error)
                }
            }
        }.resume()
    }
    
    private func addNoteToFirebase(submission: NoteSubmission, cloudinaryURL: String, completion: @escaping (Error?) -> Void) {
        let noteData: [String: Any] = [
            "name": submission.name,
            "url": cloudinaryURL,
            "semester": submission.semester,
            "subject": submission.subject ?? "",
            "uploadedBy": submission.uploadedBy,
            "uploadedDate": Timestamp(date: submission.uploadedDate),
            "isApproved": true
        ]
        
        let collection = "Notes\(submission.semester)"
        db.collection(collection).addDocument(data: noteData) { error in
            if let error = error {
                completion(error)
                return
            }
            
            self.db.collection("NotesSubmissions").document(submission.id).updateData([
                "status": "approved"
            ]) { error in
                completion(error)
            }
        }
    }
    
    private func addQuestionPaperToFirebase(submission: QuestionPaperSubmission, cloudinaryURL: String, completion: @escaping (Error?) -> Void) {
        let paperData: [String: Any] = [
            "name": submission.name,
            "url": cloudinaryURL,
            "semester": submission.semester,
            "subject": submission.subject ?? ""
        ]
        
        let collection = "Questionpaperspdf\(submission.semester)"
        db.collection(collection).addDocument(data: paperData) { error in
            if let error = error {
                completion(error)
                return
            }
            
            self.db.collection("QuestionPaperSubmissions").document(submission.id).updateData([
                "status": "approved"
            ]) { error in
                completion(error)
            }
        }
    }
    
    func rejectNote(submissionId: String, collection: String, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(submissionId).updateData([
            "status": "rejected"
        ]) { error in
            completion(error)
        }
    }
}

