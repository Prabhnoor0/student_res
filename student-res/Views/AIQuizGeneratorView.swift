//
//  AIQuizGeneratorView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI

enum GeneratorType: String, CaseIterable {
    case quiz = "Quiz"
    case questionPaper = "Question Paper"
}

struct AIQuizGeneratorView: View {
    @State private var generatorType: GeneratorType = .quiz
    @State private var selectedSemester = ""
    @State private var subject = ""
    @State private var topic = ""
    @State private var numberOfQuestions = 5
    @State private var difficulty = "Medium"
    @State private var isGenerating = false
    @State private var generatedQuiz: [QuizQuestion]? = nil
    @State private var showQuiz = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var referenceQuestionPaper: QuestionPaper? = nil
    @State private var availableQuestionPapers: [QuestionPaper] = []
    @State private var isLoadingPapers = false
    
    let semesters = ["1", "2", "3", "4", "5", "6", "7", "8"]
    let difficulties = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        NavigationStack {
            if let quiz = generatedQuiz, showQuiz {
                QuizView(questions: quiz)
            } else {
                Form {
                    Section(header: Text("Generator Type")) {
                        Picker("Type", selection: $generatorType) {
                            ForEach(GeneratorType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                    
                    Section(header: Text("Settings")) {
                        Picker("Semester", selection: $selectedSemester) {
                            Text("Select Semester").tag("")
                            ForEach(semesters, id: \.self) { sem in
                                Text("Semester \(sem)").tag(sem)
                            }
                        }
                        
                        TextField("Subject", text: $subject)
                        
                        TextField("Topic (Optional)", text: $topic)
                        
                        Stepper("Number of Questions: \(numberOfQuestions)", value: $numberOfQuestions, in: 3...20)
                        
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(difficulties, id: \.self) { diff in
                                Text(diff).tag(diff)
                            }
                        }
                    }
                    
                    if generatorType == .questionPaper {
                        Section(header: Text("Reference Question Paper (Optional)")) {
                            if isLoadingPapers {
                                HStack {
                                    ProgressView()
                                    Text("Loading question papers...")
                                }
                            } else if availableQuestionPapers.isEmpty {
                                Text("No question papers available for this semester")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Picker("Reference Paper", selection: $referenceQuestionPaper) {
                                    Text("None").tag(nil as QuestionPaper?)
                                    ForEach(availableQuestionPapers) { paper in
                                        Text(paper.name).tag(paper as QuestionPaper?)
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if !selectedSemester.isEmpty {
                                loadQuestionPapers()
                            }
                        }
                        .onChange(of: selectedSemester) { _, _ in
                            if !selectedSemester.isEmpty {
                                loadQuestionPapers()
                            } else {
                                availableQuestionPapers = []
                                referenceQuestionPaper = nil
                            }
                        }
                    }
                    
                    Section(header: Text("Instructions")) {
                        Text(generatorType == .quiz 
                             ? "Enter the subject and topic you want to generate a quiz for. The AI will create questions based on common course material."
                             : "Enter the subject and topic you want to generate a question paper for. You can optionally reference a previous question paper for style and difficulty.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        Button(action: generate) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Generating...")
                                } else {
                                    Text(generatorType == .quiz ? "Generate Quiz" : "Generate Question Paper")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(selectedSemester.isEmpty || subject.isEmpty || isGenerating)
                    }
                }
                .navigationTitle(generatorType == .quiz ? "AI Quiz Generator" : "AI Question Paper Generator")
                .navigationBarTitleDisplayMode(.large)
                .alert("Error", isPresented: $showErrorAlert) {
                    Button("OK") { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func loadQuestionPapers() {
        isLoadingPapers = true
        QuestionPaperService.quespaper.fetchquespapers(semester: selectedSemester) { papers in
            availableQuestionPapers = papers
            isLoadingPapers = false
        }
    }
    
    private func generate() {
        guard !selectedSemester.isEmpty, !subject.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showErrorAlert = true
            return
        }
        
        isGenerating = true
        
        let currentSubject = subject
        let currentTopic = topic.isEmpty ? nil : topic
        let currentCount = numberOfQuestions
        let currentDifficulty = difficulty
        
        if generatorType == .quiz {
            OpenAIService.shared.generateQuiz(
                subject: subject,
                topic: topic.isEmpty ? nil : topic,
                numberOfQuestions: numberOfQuestions,
                difficulty: difficulty
            ) { result in
                DispatchQueue.main.async {
                    isGenerating = false
                    
                    switch result {
                    case .success(let questions):
                        if questions.isEmpty {
                            errorMessage = "No questions were generated. Please try again."
                            showErrorAlert = true
                        } else {
                            generatedQuiz = questions
                            showQuiz = true
                        }
                    case .failure(let error):
                        print("OpenAI error: \(error.localizedDescription)")
                        let fallbackQuestions = generateSampleQuestions(
                            subject: currentSubject,
                            topic: currentTopic,
                            count: currentCount,
                            difficulty: currentDifficulty
                        )
                        generatedQuiz = fallbackQuestions
                        showQuiz = true
                        
                        errorMessage = "AI generation failed. Showing sample questions. Please check your OpenAI API key in OpenAIService.swift"
                        showErrorAlert = true
                    }
                }
            }
        } else {
            var referenceContent: String? = nil
            if let refPaper = referenceQuestionPaper {
                referenceContent = "Reference question paper: \(refPaper.name) from semester \(selectedSemester)"
            }
            
            OpenAIService.shared.generateQuestionPaper(
                subject: subject,
                topic: topic.isEmpty ? nil : topic,
                numberOfQuestions: numberOfQuestions,
                difficulty: difficulty,
                referencePaperContent: referenceContent
            ) { result in
                DispatchQueue.main.async {
                    isGenerating = false
                    
                    switch result {
                    case .success(let questions):
                        if questions.isEmpty {
                            errorMessage = "No questions were generated. Please try again."
                            showErrorAlert = true
                        } else {
                            generatedQuiz = questions
                            showQuiz = true
                        }
                    case .failure(let error):
                        print("OpenAI error: \(error.localizedDescription)")
                        let fallbackQuestions = generateSampleQuestions(
                            subject: currentSubject,
                            topic: currentTopic,
                            count: currentCount,
                            difficulty: currentDifficulty
                        )
                        generatedQuiz = fallbackQuestions
                        showQuiz = true
                        
                        errorMessage = "AI generation failed. Showing sample questions. Please check your OpenAI API key in OpenAIService.swift"
                        showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func generateSampleQuestions(subject: String, topic: String?, count: Int, difficulty: String) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        for i in 1...count {
            let questionText = topic != nil 
                ? "Question \(i): Explain \(topic!) in the context of \(subject)."
                : "Question \(i): What is a key concept in \(subject)?"
            
            questions.append(QuizQuestion(
                id: UUID().uuidString,
                question: questionText,
                options: [
                    "Option A: This is a sample answer",
                    "Option B: This is another sample answer",
                    "Option C: This is a third sample answer",
                    "Option D: This is a fourth sample answer"
                ],
                correctAnswer: 0,
                explanation: "This is a sample explanation. Please configure your OpenAI API key in OpenAIService.swift for AI-generated questions."
            ))
        }
        
        return questions
    }
}

struct QuizView: View {
    let questions: [QuizQuestion]
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showAnswer = false
    @State private var score = 0
    @State private var answeredQuestions: Set<Int> = []
    @Environment(\.dismiss) var dismiss
    
    var currentQuestion: QuizQuestion {
        questions[currentQuestionIndex]
    }
    
    var body: some View {
        VStack(spacing: 20) {
          
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.headline)
                Spacer()
                Text("Score: \(score)/\(answeredQuestions.count)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(currentQuestion.question)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                        Button(action: {
                            if !showAnswer {
                                selectedAnswer = index
                            }
                        }) {
                            HStack {
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                                if showAnswer {
                                    if index == currentQuestion.correctAnswer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if index == selectedAnswer && index != currentQuestion.correctAnswer {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                showAnswer 
                                    ? (index == currentQuestion.correctAnswer ? Color.green.opacity(0.2) : 
                                       (index == selectedAnswer ? Color.red.opacity(0.2) : Color.clear))
                                    : (selectedAnswer == index ? Color.blue.opacity(0.2) : Color(.systemGray6))
                            )
                            .cornerRadius(10)
                        }
                        .disabled(showAnswer)
                    }
                    
                    if showAnswer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Explanation:")
                                .font(.headline)
                            Text(currentQuestion.explanation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            HStack {
                Button(action: previousQuestion) {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(currentQuestionIndex == 0)
                
                Spacer()
                
                if !showAnswer {
                    Button(action: {
                        showAnswer = true
                        if selectedAnswer == currentQuestion.correctAnswer {
                            score += 1
                        }
                        answeredQuestions.insert(currentQuestionIndex)
                    }) {
                        Text("Check Answer")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedAnswer == nil)
                } else {
                    Button(action: nextQuestion) {
                        Label("Next", systemImage: "chevron.right")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            showAnswer = false
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            selectedAnswer = answeredQuestions.contains(currentQuestionIndex) ? selectedAnswer : nil
            showAnswer = answeredQuestions.contains(currentQuestionIndex)
        }
    }
}

#Preview {
    AIQuizGeneratorView()
}
