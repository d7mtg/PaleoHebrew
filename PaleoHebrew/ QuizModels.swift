import Foundation

// Shared models for quiz data
struct LetterPerformance: Codable {
    var correct: Int
    var total: Int
}

struct QuizResult: Codable, Identifiable {
    var id: UUID
    var date: Date
    var score: Int
    var total: Int
    var letterResults: [String: Bool] // Maps letter keys to correct/incorrect
    
    init(id: UUID = UUID(), date: Date, score: Int, total: Int, letterResults: [String: Bool]) {
        self.id = id
        self.date = date
        self.score = score
        self.total = total
        self.letterResults = letterResults
    }
}
