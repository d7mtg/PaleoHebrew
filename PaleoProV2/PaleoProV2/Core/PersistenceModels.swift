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

/// Cumulative mastery for one letter pair. `pairKey` identifies the pair and the
/// upsert (in SummaryView) fetches by it before inserting. No `.unique`
/// constraint: CloudKit sync does not support unique attributes.
@Model
final class LetterStat {
    var pairKey: String = ""
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

        // groupContainer MUST be .none: SwiftData's default .automatic relocates
        // the store into the App Group container, which is not writable on device.
        //
        // CloudKit is intentionally NOT enabled here. Setting cloudKitDatabase:
        // .automatic without the iCloud entitlement actually provisioned aborts
        // at launch (it is not a catchable throw, so a try?/fallback cannot
        // recover from it). The store is local-only. To turn on iCloud sync
        // later: add the iCloud + CloudKit capability (container
        // iCloud.d7mtg.PaleoHebrew) in Signing & Capabilities, THEN add
        // cloudKitDatabase: .automatic below.
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, groupContainer: .none)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }
}
