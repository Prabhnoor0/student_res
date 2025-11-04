//
//  UserService.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 12/10/25.
//


import FirebaseAuth
import FirebaseFirestore

final class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    func saveUserData(uid: String, data: [String: Any], completion: ((Error?) -> Void)? = nil) {
        db.collection("users").document(uid).setData(data, merge: true) { error in
            completion?(error)
        }
    }
    
    func fetchUserData(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        db.collection("users").document(uid).getDocument { document, error in
            completion(document?.data())
        }
    }
    func getsemester(completion: @escaping (String?) -> Void){
        guard let usercurr =  Auth.auth().currentUser else{
            completion(nil)
            return
        }
        let id = usercurr.uid
            fetchUserData(uid: id) { data in
                if let info = data{
                    if let semester = info["semester"] as? String{
                        completion(semester)
                    }else{
                        completion(nil)
                }
            }
        }
        
        
    }
    
    func checkAndIncrementSemester(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        fetchUserData(uid: user.uid) { [weak self] data in
            guard
                let self = self,
                let info = data,
                let semString = info["semester"] as? String,
                let currentSem = Int(semString)
            else {
                completion(false)
                return
            }
            
            let now = Date()
            let calendar = Calendar.current
            let month = calendar.component(.month, from: now)
            let day = calendar.component(.day, from: now)
            let isIncrementDay = (month == 1 && day == 1) || (month == 7 && day == 1)
            
            if let lastUpdate = info["lastSemesterUpdate"] as? Timestamp,
               calendar.isDate(lastUpdate.dateValue(), inSameDayAs: now) {
                completion(false)
                return
            }
            
            guard isIncrementDay, currentSem < 8 else {
                completion(false)
                return
            }
            
            let newSemester = currentSem + 1
            let updates: [String: Any] = [
                "semester": "\(newSemester)",
                "lastSemesterUpdate": Timestamp(date: now)
            ]
            
            self.saveUserData(uid: user.uid, data: updates) { error in
                completion(error == nil)
            }
        }
    }
    
    func isAdmin(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        if let email = user.email?.lowercased(), email == "prabhnooorkaur11@gmail.com" {
            completion(true)
            return
        }
        
        db.collection("admins").document(user.uid).getDocument { document, _ in
            completion(document?.exists ?? false)
        }
    }
    
    func requestAdminStatus(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let requestData: [String: Any] = [
            "userId": user.uid,
            "status": "pending",
            "requestedDate": Timestamp(date: Date())
        ]
        
        db.collection("adminRequests").addDocument(data: requestData, completion: completion)
    }
}
