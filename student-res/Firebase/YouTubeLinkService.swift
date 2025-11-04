//
//  YouTubeLinkService.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class YouTubeLinkService {
    static let shared = YouTubeLinkService()
    private let db = Firestore.firestore()
    
    func fetchYouTubeLinks(semester: String? = nil, searchQuery: String? = nil, completion: @escaping ([YouTubeLink]) -> Void) {
        UserService.shared.getsemester { [weak self] userSem in
            guard let self = self else { return }
            let targetSem = semester ?? userSem ?? ""
            
            let collection: String = "YouTubeLinks\(targetSem)"
            let query: Query = self.db.collection(collection).whereField("isApproved", isEqualTo: true)
            
            if let search = searchQuery, !search.isEmpty {
                var allLinks: [YouTubeLink] = []
                let semesters = ["1", "2", "3", "4", "5", "6", "7", "8"]
                let group = DispatchGroup()
                
                for sem in semesters {
                    group.enter()
                    let semCollection = "YouTubeLinks\(sem)"
                    self.db.collection(semCollection)
                        .whereField("isApproved", isEqualTo: true)
                        .getDocuments { [weak self] snapshot, error in
                            guard let self = self else {
                                group.leave()
                                return
                            }
                            if let documents = snapshot?.documents {
                                let links = documents.compactMap { doc -> YouTubeLink? in
                                    let data = doc.data()
                                    let title = (data["title"] as? String ?? "").lowercased()
                                    let subject = (data["subject"] as? String ?? "").lowercased()
                                    let description = (data["description"] as? String ?? "").lowercased()
                                    
                                    if title.contains(search.lowercased()) || 
                                       subject.contains(search.lowercased()) ||
                                       description.contains(search.lowercased()) {
                                        return YouTubeLink(
                                            id: doc.documentID,
                                            title: data["title"] as? String ?? "",
                                            url: data["url"] as? String ?? "",
                                            semester: data["semester"] as? String ?? sem,
                                            subject: data["subject"] as? String,
                                            description: data["description"] as? String,
                                            uploadedBy: data["uploadedBy"] as? String,
                                            uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue(),
                                            isApproved: data["isApproved"] as? Bool ?? false
                                        )
                                    }
                                    return nil
                                }
                                allLinks.append(contentsOf: links)
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    completion(allLinks)
                }
                return
            }
            
            query.getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion([])
                    return
                }
                if let err = error {
                    print("Error fetching YouTube links: \(err)")
                    completion([])
                    return
                }
                
                let links: [YouTubeLink] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return YouTubeLink(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        url: data["url"] as? String ?? "",
                        semester: data["semester"] as? String ?? targetSem,
                        subject: data["subject"] as? String,
                        description: data["description"] as? String,
                        uploadedBy: data["uploadedBy"] as? String,
                        uploadedDate: (data["uploadedDate"] as? Timestamp)?.dateValue(),
                        isApproved: data["isApproved"] as? Bool ?? false
                    )
                } ?? []
                
                completion(links)
            }
        }
    }
    
    func submitYouTubeLink(title: String, url: String, semester: String, subject: String?, description: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let linkData: [String: Any] = [
            "title": title,
            "url": url,
            "semester": semester,
            "subject": subject ?? "",
            "description": description ?? "",
            "uploadedBy": user.uid,
            "uploadedDate": Timestamp(date: Date()),
            "isApproved": false,
            "status": "pending"
        ]
        
        self.db.collection("YouTubeLinkSubmissions").addDocument(data: linkData) { error in
            completion(error)
        }
    }
}

