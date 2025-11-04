//
//  OpenAIService.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import Foundation

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

final class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey: String = Secrets.openAIKey
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    func generateQuestionPaper(subject: String, topic: String?, numberOfQuestions: Int, difficulty: String, referencePaperContent: String?, completion: @escaping (Result<[QuizQuestion], Error>) -> Void) {
        guard apiKey != Secrets.openAIKey
        else {
            completion(.failure(NSError(domain: "OpenAIError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please set your OpenAI API key in OpenAIService.swift"])))
            return
        }
        
        let topicText = topic?.isEmpty == false ? " on the topic: \(topic!)" : ""
        let referenceText = referencePaperContent?.isEmpty == false ? "\n\nUse the following previous question paper as a reference for style and difficulty:\n\(referencePaperContent!)" : ""
        
        let prompt = """
        Generate \(numberOfQuestions) question paper questions for the subject: \(subject)\(topicText).
        Difficulty level: \(difficulty)
        \(referenceText)
        
        For each question, provide:
        1. A clear, comprehensive question (can be short answer, long answer, or problem-solving type)
        2. Four answer options (A, B, C, D) for multiple choice, or provide expected answer format
        3. The correct answer (0-indexed: 0=A, 1=B, 2=C, 3=D) or mark scheme
        4. A brief explanation or marking scheme
        
        Format the response as a JSON array with this structure:
        [
          {
            "question": "Question text here",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correctAnswer": 0,
            "explanation": "Explanation or marking scheme here"
          }
        ]
        
        Make sure the questions are relevant to \(subject) and appropriate for \(difficulty) difficulty level. If a reference paper was provided, match its style and difficulty.
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIRequest.Message(role: "system", content: "You are an educational question paper generator. Always respond with valid JSON only."),
                OpenAIRequest.Message(role: "user", content: prompt)
            ],
            temperature: 0.7
        )
        
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? [String: Any],
                   let message = errorMessage["message"] as? String {
                    completion(.failure(NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed"])))
                }
                return
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let content = openAIResponse.choices.first?.message.content ?? ""
                let jsonString = self.extractJSON(from: content)
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    completion(.failure(NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])))
                    return
                }
                
                let questions = try JSONDecoder().decode([QuizQuestionResponse].self, from: jsonData)
                let quizQuestions = questions.map { q in
                    QuizQuestion(
                        id: UUID().uuidString,
                        question: q.question,
                        options: q.options,
                        correctAnswer: q.correctAnswer,
                        explanation: q.explanation
                    )
                }
                
                completion(.success(quizQuestions))
            } catch {
                print("Error parsing OpenAI response: \(error)")
                print("Response content: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func generateQuiz(subject: String, topic: String?, numberOfQuestions: Int, difficulty: String, completion: @escaping (Result<[QuizQuestion], Error>) -> Void) {
        guard apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            completion(.failure(NSError(domain: "OpenAIError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please set your OpenAI API key in OpenAIService.swift"])))
            return
        }
        
        let topicText = topic?.isEmpty == false ? " on the topic: \(topic!)" : ""
        let prompt = """
        Generate \(numberOfQuestions) multiple-choice quiz questions for the subject: \(subject)\(topicText).
        Difficulty level: \(difficulty)
        
        For each question, provide:
        1. A clear, concise question
        2. Four answer options (A, B, C, D)
        3. The correct answer (0-indexed: 0=A, 1=B, 2=C, 3=D)
        4. A brief explanation
        
        Format the response as a JSON array with this structure:
        [
          {
            "question": "Question text here",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correctAnswer": 0,
            "explanation": "Explanation text here"
          }
        ]
        
        Make sure the questions are relevant to \(subject) and appropriate for \(difficulty) difficulty level.
        """
        
        let requestBody = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIRequest.Message(role: "system", content: "You are an educational quiz generator. Always respond with valid JSON only."),
                OpenAIRequest.Message(role: "user", content: prompt)
            ],
            temperature: 0.7
        )
        
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? [String: Any],
                   let message = errorMessage["message"] as? String {
                    completion(.failure(NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed"])))
                }
                return
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let content = openAIResponse.choices.first?.message.content ?? ""
            
                let jsonString = self.extractJSON(from: content)
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    completion(.failure(NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])))
                    return
                }
                
                let questions = try JSONDecoder().decode([QuizQuestionResponse].self, from: jsonData)
                let quizQuestions = questions.map { q in
                    QuizQuestion(
                        id: UUID().uuidString,
                        question: q.question,
                        options: q.options,
                        correctAnswer: q.correctAnswer,
                        explanation: q.explanation
                    )
                }
                
                completion(.success(quizQuestions))
            } catch {
                print("Error parsing OpenAI response: \(error)")
                print("Response content: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct QuizQuestionResponse: Codable {
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
}

