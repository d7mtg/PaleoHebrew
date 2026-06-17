import SwiftUI

/// Drives the Play quiz: a four-phase state machine plus question generation
/// and scoring. `@Observable` so views invalidate only on the properties they
/// read.
@MainActor
@Observable
final class QuizEngine {
    enum Phase: Equatable { case splash, question, loading, summary }

    struct Question: Identifiable, Equatable {
        let id = UUID()
        let letter: PaleoLetter
        let promptIsPaleo: Bool
        let options: [String]

        var prompt: String { promptIsPaleo ? letter.paleo : letter.modern }
        var correct: String { promptIsPaleo ? letter.modern : letter.paleo }
    }

    let total = 10

    private(set) var phase: Phase = .splash
    private(set) var questions: [Question] = []
    private(set) var index = 0
    private(set) var score = 0
    private(set) var outcomes: [LetterOutcome] = []
    private(set) var picked: String?
    private(set) var results: [Bool?] = []
    private(set) var loadingProgress: Double = 0

    private var advanceTask: Task<Void, Never>?
    private var loadingTask: Task<Void, Never>?

    var current: Question? { questions.indices.contains(index) ? questions[index] : nil }
    var isAnswered: Bool { picked != nil }
    var percent: Double { total > 0 ? Double(score) / Double(total) : 0 }

    // MARK: Lifecycle

    func start() {
        cancelTimers()
        questions = (0..<total).map { _ in Self.makeQuestion() }
        results = Array(repeating: nil, count: total)
        index = 0
        score = 0
        outcomes = []
        picked = nil
        loadingProgress = 0
        phase = .question
    }

    func answer(_ option: String) {
        guard picked == nil, let q = current else { return }
        picked = option
        let correct = option == q.correct
        if correct { score += 1 }
        results[index] = correct
        outcomes.append(
            LetterOutcome(
                paleo: q.letter.paleo,
                modern: q.letter.modern,
                name: q.letter.name,
                promptWasPaleo: q.promptIsPaleo,
                correctAnswer: q.correct,
                picked: option,
                isCorrect: correct
            )
        )
        if correct {
            advanceTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2.2))
                if !Task.isCancelled { self?.next() }
            }
        }
    }

    func next() {
        advanceTask?.cancel()
        picked = nil
        if index + 1 < total {
            index += 1
        } else {
            phase = .summary
        }
    }

    func reset() {
        cancelTimers()
        phase = .splash
        picked = nil
        index = 0
        score = 0
        outcomes = []
        questions = []
        results = []
        loadingProgress = 0
    }

    private func beginLoading() {
        phase = .loading
        loadingProgress = 0
        loadingTask = Task { [weak self] in
            guard let self else { return }
            while self.loadingProgress < 1 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled { return }
                self.loadingProgress = min(1, self.loadingProgress + 0.03)
            }
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled { self.phase = .summary }
        }
    }

    private func cancelTimers() {
        advanceTask?.cancel()
        loadingTask?.cancel()
    }

    // MARK: Question generation

    static func makeQuestion() -> Question {
        let letter = Alphabet.letters.randomElement()!
        let promptIsPaleo = Bool.random()
        let correct = promptIsPaleo ? letter.modern : letter.paleo

        var seen: Set<String> = [correct]
        var options = [correct]
        for other in Alphabet.letters.shuffled() {
            let candidate = promptIsPaleo ? other.modern : other.paleo
            if seen.insert(candidate).inserted { options.append(candidate) }
            if options.count == 4 { break }
        }
        return Question(letter: letter, promptIsPaleo: promptIsPaleo, options: options.shuffled())
    }
}
