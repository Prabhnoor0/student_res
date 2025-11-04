//
//  CloudinaryService.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import Foundation
import UIKit

struct CloudinaryUploadResponse: Codable {
    let secure_url: String
    let public_id: String
    let format: String
    let resource_type: String
}

final class CloudinaryService {
    static let shared = CloudinaryService()
    
    private let cloudName = Secrets.cloudinaryCloudName
    private let uploadPreset = "ml_default"
    private let apiKey = Secrets.cloudinaryApiKey
    private let apiSecret = Secrets.cloudinaryApiSecret
    
    private init() {}
    
    func uploadPDF(fileURL: URL, folder: String = "student-resources", completion: @escaping (Result<String, Error>) -> Void) {
        guard cloudName != "YOUR_CLOUD_NAME" else {
            completion(.failure(NSError(domain: "CloudinaryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please configure Cloudinary credentials in CloudinaryService.swift"])))
            return
        }
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            completion(.failure(NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file"])))
            return
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read file data"])))
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/auto/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(folder)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? [String: Any],
                   let message = errorMessage["message"] as? String {
                    completion(.failure(NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])))
                }
                return
            }
            
            do {
                let uploadResponse = try JSONDecoder().decode(CloudinaryUploadResponse.self, from: data)
                completion(.success(uploadResponse.secure_url))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func uploadPDFFromData(data: Data, fileName: String, folder: String = "student-resources", completion: @escaping (Result<String, Error>) -> Void) {
        guard cloudName != "YOUR_CLOUD_NAME" else {
            completion(.failure(NSError(domain: "CloudinaryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please configure Cloudinary credentials in CloudinaryService.swift"])))
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/auto/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(folder)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? [String: Any],
                   let message = errorMessage["message"] as? String {
                    completion(.failure(NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])))
                }
                return
            }
            
            do {
                let uploadResponse = try JSONDecoder().decode(CloudinaryUploadResponse.self, from: data)
                completion(.success(uploadResponse.secure_url))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

