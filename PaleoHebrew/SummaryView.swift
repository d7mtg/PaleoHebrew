import SwiftUI

struct SummaryView: View {
    let score: Int
    let total: Int
    let questions: [QuizQuestion]
    let outcomes: [Bool?]
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    
    // For saving letter performance stats
    @AppStorage("letterPerformance") private var letterPerformanceData: Data = Data()
    @State private var letterPerformance: [String: LetterPerformance] = [:]
    
    // For saving quiz history
    @AppStorage("quizHistory") private var quizHistoryData: Data = Data()
    
    // For history view
    @State private var showingHistory = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 8) {
                // Dynamic header based on score
                VStack(spacing: 8) {
                    Text(summaryTitle)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(summaryColor)

                    Text("\(score) out of \(total) correct")
                        .font(.title3)
                }
                .padding(.top, 16)
                
                Divider()
                    .padding(.top, 28)
                
                // Results list with fade effect
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<questions.count, id: \.self) { index in
                                let question = questions[index]
                                let isCorrect = outcomes[index] ?? false
                                
                                // Find the user's selected answer
                                let userSelectedAnswer = getUserSelectedAnswer(for: question, at: index)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    // Question type as header
                                    Text(question.questionType == .paleoToModern ? "Paleo → Modern" : "Modern → Paleo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    HStack {
                                        HStack(spacing: 4) {
                                            Text(question.letter.paleo)
                                                .font(.system(size: 24))
                                            Text("→")
                                                .foregroundColor(.secondary)
                                            Text(question.letter.modern)
                                                .font(.system(size: 24))
                                        }
                                        .frame(width: 100, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        if isCorrect {
                                            // Correct answer
                                            HStack {
                                                Text("Correct!")
                                                    .foregroundColor(.green)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.title3)
                                            }
                                        } else {
                                            // Wrong answer - show both user's answer and correct answer
                                            VStack(alignment: .trailing, spacing: 6) {
                                                HStack {
                                                    Text("Your answer:")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(userSelectedAnswer)
                                                        .font(.body)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.red.opacity(0.1))
                                                        .cornerRadius(4)
                                                }
                                                
                                                HStack {
                                                    Text("Correct:")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(question.correctAnswer)
                                                        .font(.body)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.green.opacity(0.1))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                            
                            // Add some space at the bottom
                            Color.clear
                                .frame(height: 40)
                        }
                        .padding(.vertical)
                    }
                    
                    // Simple fade gradient at bottom
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                }
                
                Spacer()
                
                // Buttons with reduced top padding
                VStack(spacing: 12) {
                    Button(actionButtonTitle) {
                        onPlayAgain()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("View History") {
                        showingHistory = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 4) // Reduced padding
                .padding(.bottom, 16)
            }
            
            // X button overlay at top right
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onExit) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(Circle())
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 16)
                }
                
                Spacer()
            }
        }
        .onAppear {
            saveResults()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
    
    // Dynamic text based on score
    private var summaryTitle: String {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.9 {
            return "Excellent!"
        } else if percentage >= 0.7 {
            return "Well Done!"
        } else if percentage >= 0.5 {
            return "Good Job!"
        } else {
            return "Keep Practicing!"
        }
    }
    
    // Dynamic color based on score
    private var summaryColor: Color {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.9 {
            return .green
        } else if percentage >= 0.7 {
            return .blue
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Dynamic action button text based on score
    private var actionButtonTitle: String {
        let percentage = Double(score) / Double(total)
        
        if percentage >= 0.8 {
            return "Play Again"
        } else if percentage >= 0.5 {
            return "Try Again"
        } else {
            return "Practice More"
        }
    }
    
    // Helper to find user's selected answer
    private func getUserSelectedAnswer(for question: QuizQuestion, at index: Int) -> String {
        // This is a simplified approach - you may need to adjust based on your actual data structure
        // Assuming the user's selected answer is stored in outcomes
        if let isCorrect = outcomes[index], !isCorrect {
            // If wrong, find the answer that's not the correct one
            for option in question.options {
                if option != question.correctAnswer {
                    return option
                }
            }
        }
        return question.correctAnswer
    }
    
    private func saveResults() {
        // Load existing data for letter performance
        do {
            if let savedData = try? JSONDecoder().decode([String: LetterPerformance].self, from: letterPerformanceData) {
                letterPerformance = savedData
            }
        }
        
        // Update letter performance stats
        for (index, question) in questions.enumerated() {
            let letterKey = "\(question.letter.paleo)_\(question.letter.modern)"
            let isCorrect = outcomes[index] ?? false
            
            if let existing = letterPerformance[letterKey] {
                letterPerformance[letterKey] = LetterPerformance(
                    correct: existing.correct + (isCorrect ? 1 : 0),
                    total: existing.total + 1
                )
            } else {
                letterPerformance[letterKey] = LetterPerformance(
                    correct: isCorrect ? 1 : 0,
                    total: 1
                )
            }
        }
        
        // Create a record of letter results for this quiz
        var letterResults: [String: Bool] = [:]
        for (index, question) in questions.enumerated() {
            let letterKey = "\(question.letter.paleo)_\(question.letter.modern)"
            letterResults[letterKey] = outcomes[index] ?? false
        }
        
        // Load existing quiz history
        var quizHistory: [QuizResult] = []
        if let savedData = try? JSONDecoder().decode([QuizResult].self, from: quizHistoryData) {
            quizHistory = savedData
        }
        
        // Create a new quiz result
        let newResult = QuizResult(
            date: Date(),
            score: score,
            total: total,
            letterResults: letterResults
        )
        
        // Add to history (limit to last 20 quizzes to prevent excessive storage)
        quizHistory.append(newResult)
        if quizHistory.count > 20 {
            quizHistory = Array(quizHistory.sorted(by: { $0.date > $1.date }).prefix(20))
        }
        
        // Save updated data
        do {
            letterPerformanceData = try JSONEncoder().encode(letterPerformance)
            quizHistoryData = try JSONEncoder().encode(quizHistory)
        } catch {
            print("Failed to save data: \(error)")
        }
    }
}

// Primary button style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// Secondary button style for the history button
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .padding(.horizontal)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    SummaryView(
        score: 7,
        total: 10,
        questions: [
            QuizQuestion(
                letter: PaleoLetter(paleo: "𐤀", modern: "א", name: "Aleph"),
                questionType: .paleoToModern,
                options: ["א", "ב", "ג", "ד"],
                correctAnswer: "א"
            ),
            QuizQuestion(
                letter: PaleoLetter(paleo: "𐤁", modern: "ב", name: "Bet"),
                questionType: .modernToPaleo,
                options: ["𐤀", "𐤁", "𐤂", "𐤃"],
                correctAnswer: "𐤁"
            ),
            
            QuizQuestion(
                letter: PaleoLetter(paleo: "𐤂", modern: "ג", name: "Gimel"),
                questionType: .paleoToModern,
                options: ["א", "ב", "ג", "ד"],
                correctAnswer: "ג"
            )
        ],
        outcomes: [true, false, true],
        onPlayAgain: {},
        onExit: {}
    )
}
