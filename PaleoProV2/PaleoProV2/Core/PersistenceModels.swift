import Foundation
import SwiftData

/// One question's outcome inside a quiz. Unlike V1, the glyph the user actually
/// tapped (`picked`) is recorded, so detail views can show the real mistake.
struct LetterOutcome: Codable, Hashable, Sendable {
    var paleo: String
    var modern: String
    var name: String
    var promptWasPaleo: Bool
    var correctAnswer: String
    var picked: String?
    var isCorrect: Bool

    var pairKey: String { "\(paleo)_\(modern)" }
}

/// A completed quiz, persisted with SwiftData.
@Model
final class QuizRecord {
    var date: Date = Date.now
    var score: Int = 0
    var total: Int = 0
    var outcomes: [LetterOutcome] = []

    init(date: Date, score: Int, total: Int, outcomes: [LetterOutcome]) {
        self.date = date
        self.score = score
        self.total = total
        self.outcomes = outcomes
    }

    var percent: Double { total > 0 ? Double(score) / Double(total) : 0 }
}

/// Cumulative mastery for one letter pair, keyed uniquely so upserts are cheap.
@Model
final class LetterStat {
    @Attribute(.unique) var pairKey: String = ""
    var name: String = ""
    var correct: Int = 0
    var total: Int = 0

    init(pairKey: String, name: String, correct: Int = 0, total: Int = 0) {
        self.pairKey = pairKey
        self.name = name
        self.correct = correct
        self.total = total
    }

    var mastery: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}

/// One saved conversion, so the Convert tab can keep a history.
@Model
final class ConversionRecord {
    var date: Date = Date.now
    var source: String = ""
    var result: String = ""
    /// true = Modern → Paleo, false = Paleo → Modern.
    var modernToPaleo: Bool = true

    init(date: Date, source: String, result: String, modernToPaleo: Bool) {
        self.date = date
        self.source = source
        self.result = result
        self.modernToPaleo = modernToPaleo
    }
}

@MainActor
enum Persistence {
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([QuizRecord.self, LetterStat.self, ConversionRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }
}
