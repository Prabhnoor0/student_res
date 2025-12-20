//
//  YouTubeLink.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 29/12/25.
//

import Foundation

struct YouTubeLink: Identifiable, Codable {
    var id: String
    var title: String
    var url: String
    var semester: String
    var subject: String?
    var description: String?
    var uploadedBy: String?
    var uploadedDate: Date?
    var isApproved: Bool
}

