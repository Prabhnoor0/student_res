//
//  ProfileView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct ProfileView: View {
    @Binding var userName: String
    @Binding var userProfileImageURL: String?
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedImageURL: String? = nil
    @State private var enrollmentNumber = ""
    @State private var semester = ""
    @State private var editedSemester = ""
    @State private var branch = ""
    @State private var email = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var isUploading = false
    @State private var showLogoutAlert = false
    @State private var showSettings = false
    @State private var isAdmin = false
    @State private var adminRequestStatus = ""
    @State private var showAdminRequestAlert = false
    @State private var showBecameAdminAlert = false
    @State private var showAdminDashboard = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                            } else if let imageURL = editedImageURL ?? userProfileImageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                            }
                            
                            if isEditing {
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Text("Change Photo")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Personal Information")) {
                    if isEditing {
                        TextField("Name", text: $editedName)
                        TextField("Profile Image URL", text: Binding(
                            get: { editedImageURL ?? "" },
                            set: { editedImageURL = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    } else {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(userName.isEmpty ? "Not set" : userName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email.isEmpty ? "Not set" : email)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Enrollment Number")
                        Spacer()
                        Text(enrollmentNumber.isEmpty ? "Not set" : enrollmentNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    if isEditing {
                        Picker("Semester", selection: $editedSemester) {
                            Text("Select Semester").tag("")
                            ForEach(["1", "2", "3", "4", "5", "6", "7", "8"], id: \.self) { sem in
                                Text("Semester \(sem)").tag(sem)
                            }
                        }
                    } else {
                        HStack {
                            Text("Semester")
                            Spacer()
                            Text(semester.isEmpty ? "Not set" : "Semester \(semester)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Branch")
                        Spacer()
                        Text(branch.isEmpty ? "Not set" : branch)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    if isEditing {
                        Button(action: saveProfile) {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isUploading)
                        
                        Button(action: {
                            isEditing = false
                            editedName = userName
                            editedImageURL = userProfileImageURL
                            editedSemester = semester
                            selectedImage = nil
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        Button(action: {
                            isEditing = true
                            editedName = userName
                            editedImageURL = userProfileImageURL
                            editedSemester = semester
                        }) {
                            Text("Edit Profile")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                    }
                    
                    if isAdmin {
                        NavigationLink(destination: AdminDashboardView()) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                                Text("Admin Dashboard")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        if adminRequestStatus.isEmpty {
                            Button(action: requestAdminStatus) {
                                HStack {
                                    Image(systemName: "person.badge.key.fill")
                                    Text("Request Admin Access")
                                }
                                .foregroundColor(.blue)
                            }
                        } else {
                            HStack {
                                Image(systemName: adminRequestStatus == "approved" ? "checkmark.circle.fill" : "clock.fill")
                                Text("Admin Request: \(adminRequestStatus.capitalized)")
                            }
                            .foregroundColor(adminRequestStatus == "approved" ? .green : .orange)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert("Admin Request Submitted", isPresented: $showAdminRequestAlert) {
                Button("OK") { }
            } message: {
                Text("Your admin request has been submitted. You will be notified once it's reviewed.")
            }
            .alert("You are now an admin", isPresented: $showBecameAdminAlert) {
                Button("Open Admin Dashboard") {
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your admin request was approved. You now have access to the Admin Dashboard.")
            }
            .onAppear {
                loadUserData()
                UserService.shared.checkAndIncrementSemester { didIncrement in
                    if didIncrement {
                        loadUserData()
                    }
                }
            }
        }
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        email = user.email ?? ""
        
        UserService.shared.fetchUserData(uid: user.uid) { data in
            if let data = data {
                userName = data["name"] as? String ?? ""
                userProfileImageURL = data["profileImageURL"] as? String
                enrollmentNumber = data["enrollmentnumber"] as? String ?? ""
                semester = data["semester"] as? String ?? ""
                branch = data["branch"] as? String ?? ""
                
                editedName = userName
                editedImageURL = userProfileImageURL
                editedSemester = semester
            }
        }
        
        UserService.shared.isAdmin { isAdmin in
            let wasAdmin = self.isAdmin
            self.isAdmin = isAdmin
            
            if !wasAdmin && isAdmin {
                self.showBecameAdminAlert = true
            }
        }
        checkAdminRequestStatus()
    }
    
    private func checkAdminRequestStatus() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("adminRequests")
            .whereField("userId", isEqualTo: user.uid)
            .order(by: "requestedDate", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents, let doc = documents.first {
                    self.adminRequestStatus = doc.data()["status"] as? String ?? ""
                }
            }
    }
    
    private func requestAdminStatus() {
        UserService.shared.requestAdminStatus { error in
            if let error = error {
                print("Error requesting admin status: \(error)")
            } else {
                adminRequestStatus = "pending"
                showAdminRequestAlert = true
            }
        }
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        isUploading = true
        if let image = selectedImage {
            uploadProfileImage(image: image) { imageURL in
                if let imageURL = imageURL {
                    self.editedImageURL = imageURL
                }
                self.saveUserData()
            }
        } else {
            saveUserData()
        }
    }
    
    private func uploadProfileImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5),
              let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("profile_images/\(user.uid).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let url = url {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func saveUserData() {
        guard let user = Auth.auth().currentUser else {
            isUploading = false
            return
        }
        
        var userData: [String: Any] = [
            "name": editedName
        ]
        
        if let imageURL = editedImageURL {
            userData["profileImageURL"] = imageURL
        }
        if !editedSemester.isEmpty {
            userData["semester"] = editedSemester
        }
        
        UserService.shared.saveUserData(uid: user.uid, data: userData) { error in
            isUploading = false
            if error == nil {
                userName = editedName
                userProfileImageURL = editedImageURL
                semester = editedSemester
                isEditing = false
                selectedImage = nil
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ProfileView(userName: .constant("John Doe"), userProfileImageURL: .constant(nil))
}

