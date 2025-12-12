//
//  quespapermodel.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 24/10/25.
//

struct  QuestionPaper: Identifiable,Hashable{
   var id: String
   var name: String
   var  url: String
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: QuestionPaper, rhs: QuestionPaper) -> Bool {
        lhs.id == rhs.id
    }
}
