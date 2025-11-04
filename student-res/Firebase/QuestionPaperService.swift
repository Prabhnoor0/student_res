//
//  QuestionPaperService.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 24/10/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class QuestionPaperService {
    static let quespaper = QuestionPaperService()
    private let db = Firestore.firestore()
    
    func fetchquespapers(semester: String? = nil, completion: @escaping ([QuestionPaper]) -> Void) {
        UserService.shared.getsemester { [weak self] userSem in
            guard let self = self else { return }
            let targetSem = semester ?? userSem ?? ""
            
            guard !targetSem.isEmpty else {
                completion([])
                return
            }
            
            let collection = "Questionpaperspdf\(targetSem)"
            self.db.collection(collection).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching question papers: \(error)")
                    completion([])
                    return
                }
                
                let papers: [QuestionPaper] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let name = data["name"] as? String,
                        let url = data["url"] as? String
                    else { return nil }
                    
                    return QuestionPaper(
                        id: doc.documentID,
                        name: name,
                        url: url
                    )
                } ?? []
                
                completion(papers)
            }
        }
    }
    
    func submitQuestionPaper(
        name: String,
        url: String,
        semester: String,
        subject: String?,
        completion: @escaping (Error?) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let submissionData: [String: Any] = [
            "name": name,
            "url": url,
            "semester": semester,
            "subject": subject ?? "",
            "uploadedBy": user.uid,
            "uploadedDate": Timestamp(date: Date()),
            "status": "pending"
        ]
        
        db.collection("QuestionPaperSubmissions").addDocument(data: submissionData) { error in
            completion(error)
        }
    }
}

