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

        func build(_ config: ModelConfiguration) -> ModelContainer? {
            try? ModelContainer(for: schema, configurations: [config])
        }

        // groupContainer MUST be .none. With the default .automatic, SwiftData
        // relocates the store into the App Group container (the app has that
        // entitlement for the keyboard/widget); on device its Application
        // Support dir doesn't exist and the sandbox denies creating it, so the
        // store fails on launch and the watchdog kills the app.
        if inMemory {
            if let c = build(.init(schema: schema, isStoredInMemoryOnly: true, groupContainer: .none)) { return c }
            fatalError("Unable to create in-memory ModelContainer")
        }

        // Prefer a CloudKit-backed store so quiz progress and conversion history
        // sync across the user's devices. If iCloud isn't provisioned/available
        // (e.g. the capability hasn't been enabled, or the user isn't signed in),
        // fall back to a purely local store so the app always launches. To turn
        // sync on, add the iCloud + CloudKit capability with the container
        // iCloud.d7mtg.PaleoHebrew in Xcode's Signing & Capabilities.
        if let c = build(.init(schema: schema, groupContainer: .none, cloudKitDatabase: .automatic)) { return c }
        if let c = build(.init(schema: schema, groupContainer: .none, cloudKitDatabase: .none)) { return c }
        fatalError("Unable to create ModelContainer")
    }
}
