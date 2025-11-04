//
//  NotesService.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class NotesService {
    static let shared = NotesService()
    private let db = Firestore.firestore()
    
    func fetchNotes(semester: String? = nil, searchQuery: String? = nil, completion: @escaping ([Note]) -> Void) {
        UserService.shared.getsemester { [weak self] userSem in
            guard let self = self else { return }
            let targetSem = semester ?? userSem ?? ""
            
            let collection: String = "Notes\(targetSem)"
            let query: Query = self.db.collection(collection).whereField("isApproved", isEqualTo: true)
            
            if let search = searchQuery, !search.isEmpty {
                var allNotes: [Note] = []
                let semesters = ["1", "2", "3", "4", "5", "6", "7", "8"]
                let group = DispatchGroup()
                
                for sem in semesters {
                    group.enter()
                    let semCollection = "Notes\(sem)"
                    self.db.collection(semCollection)
                        .whereField("isApproved", isEqualTo: true)
                        .getDocuments { [weak self] snapshot, error in
                            guard let self = self else {
                                group.leave()
                                return
                            }
                            if let documents = snapshot?.documents {
                                let notes = documents.compactMap { doc -> Note? in
                                    let data = doc.data()
                                    let name = (data["name"] as? String ?? "").lowercased()
                                    let subject = (data["subject"] as? String ?? "").lowercased()
                                    
                                    if name.contains(search.lowercased()) || subject.contains(search.lowercased()) {
                                        return Note(
                                            id: doc.documentID,
                                            name: data["name"] as? String ?? "",
                                            url: data["url"] as? String ?? "",
                                            semester: data["semester"] as? String ?? sem,
                                            subject: data["subject"] as? String,
                                            uploadedBy: data["uploadedBy"] as? String,
                                            uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue(),
                                            isApproved: data["isApproved"] as? Bool ?? false
                                        )
                                    }
                                    return nil
                                }
                                allNotes.append(contentsOf: notes)
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    completion(allNotes)
                }
                return
            }
            
            query.getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion([])
                    return
                }
                if let err = error {
                    print("Error fetching notes: \(err)")
                    completion([])
                    return
                }
                
                let notes: [Note] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Note(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        url: data["url"] as? String ?? "",
                        semester: data["semester"] as? String ?? targetSem,
                        subject: data["subject"] as? String,
                        uploadedBy: data["uploadedBy"] as? String,
                        uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue(),
                        isApproved: data["isApproved"] as? Bool ?? false
                    )
                } ?? []
                
                completion(notes)
            }
        }
    }
    
    func submitNote(name: String, url: String, semester: String, subject: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let noteData: [String: Any] = [
            "name": name,
            "url": url,
            "semester": semester,
            "subject": subject ?? "",
            "uploadedBy": user.uid,
            "uploadedDate": Timestamp(date: Date()),
            "isApproved": false,
            "status": "pending"
        ]
        
        self.db.collection("NotesSubmissions").addDocument(data: noteData) { error in
            completion(error)
        }
    }
}

