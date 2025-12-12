//
//  newpage.swift
//  student-res
//
//  Created by Prabhnoor Kaur on 11/10/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct QuestionPapers: View {
    @State var questionpapers: [QuestionPaper] = []
    @State var isloading: Bool = true
    @State private var userSemester: String = ""
    @State private var selectedSemester: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if !userSemester.isEmpty {
                            Button(action: {
                                selectedSemester = userSemester
                                quespaperss()
                            }) {
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text("My Sem \(userSemester)")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSemester == userSemester ? Color.green : Color(.systemGray5))
                                .foregroundColor(selectedSemester == userSemester ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                        
                        ForEach(["1", "2", "3", "4", "5", "6", "7", "8"], id: \.self) { sem in
                            if sem != userSemester {
                                Button(action: {
                                    selectedSemester = sem
                                    quespaperss()
                                }) {
                                    Text("Sem \(sem)")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedSemester == sem ? Color.green : Color(.systemGray5))
                                        .foregroundColor(selectedSemester == sem ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                if(isloading){
                    Spacer()
                    ProgressView("Fetching question papers...")
                    Spacer()
                }
                else if(questionpapers.isEmpty){
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Question papers not available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }else{
                    List(questionpapers){ paper in
                        Button(paper.name) {
                            openpdf(url: paper.url)
                        }
                    }
                }
            }
            .navigationTitle("Question Papers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SubmitQuestionPaperForReviewView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                loadUserSemester()
            }
        }
    }
    
    private func loadUserSemester() {
        UserService.shared.getsemester { sem in
            userSemester = sem ?? ""
            if selectedSemester == nil {
                selectedSemester = userSemester.isEmpty ? nil : userSemester
            }
            quespaperss()
        }
    }
        
    
    
    
    func quespaperss(){
        isloading = true
        let targetSem = selectedSemester ?? userSemester
        QuestionPaperService.quespaper.fetchquespapers(semester: targetSem.isEmpty ? nil : targetSem) { papers in
            questionpapers = papers
            isloading = false
        }
    }
    func openpdf(url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    QuestionPapers()
}
