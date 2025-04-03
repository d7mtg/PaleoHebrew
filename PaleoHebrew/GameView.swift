import SwiftUI

// MARK: - Custom Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Models and Enums

enum GamePhase {
    case splash
    case question
    case loading
    case summary
}

enum QuestionType {
    case paleoToModern // Show the Paleo letter, ask for its modern equivalent.
    case modernToPaleo // Show the modern letter, ask for its Paleo version.
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let letter: PaleoLetter
    let questionType: QuestionType
    let options: [String]
    let correctAnswer: String
}

// MARK: - GameView

struct GameView: View {
    @State private var gamePhase: GamePhase = .splash
    @State private var questions: [QuizQuestion] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var score: Int = 0
    @State private var showingHistory = false

    // For coloring/haptic feedback
    @State private var selectedAnswer: String? = nil
    @State private var isAnswered = false
    
    // Used to cancel auto-advance if the user hits Next
    @State private var autoAdvanceTask: DispatchWorkItem?
    @State private var outcomes: [Bool?] = []
    
    // For loading animation
    @State private var loadingProgress: Double = 0
    @State private var loadingTimer: Timer?
    
    var body: some View {
        switch gamePhase {
        case .splash:
            splashView
        case .question:
            questionView
        case .loading:
            loadingView
        case .summary:
            summaryView
        }
    }
    
    // MARK: Splash View
    
    var splashView: some View {
        ZStack {
            InteractiveBackgroundView()
                .ignoresSafeArea(edges: [.top, .leading, .trailing])
            
            VStack {
               
                Spacer()
                
                VStack {
                    Text("Learn Paleo Hebrew")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                     
                    Spacer()
                    Text("Master the ancient script with simple lessons.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: 280) // Makes the VStack narrower
                
                .frame(maxHeight: 120)

                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    // Start a new game
                    questions = generateQuestions(count: 10)
                    currentQuestionIndex = 0
                    score = 0
                    outcomes = Array(repeating: nil, count: 10)
                    gamePhase = .question
                } label: {
                    Text("Start Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal)
                
                // History button
                Button {
                    showingHistory = true
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View History")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
        }
    }
    
    // MARK: Question View
    
    var questionView: some View {
        VStack {
            // MARK: Progress Header
            HStack {
                Text("\(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.headline)
                Spacer()
                Button(action: resetGame) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            HStack(spacing: 4) {
                ForEach(0..<questions.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForProgress(at: index))
                        .frame(height: 6)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Large, bold, centered prompt letter
            let currentQuestion = questions[currentQuestionIndex]
            Text(currentQuestion.questionType == .paleoToModern ? currentQuestion.letter.paleo : currentQuestion.letter.modern)
                .font(.system(size: 180, weight: .bold))
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            // Answer buttons in a row
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(currentQuestion.options, id: \.self) { option in
                    Button {
                        answerTapped(option: option)
                    } label: {
                        ZStack {
                            // Background
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.systemBackground))
                            
                            if option == selectedAnswer {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 8)
                                    .fill(Color.white)

                            }
                            
                            if option == selectedAnswer {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 4)
                                    .fill(Color.white)
                            }
                            
                            // Inner fill depending on answer state
                            RoundedRectangle(cornerRadius: 10)
                                .fill(buttonColor(for: option))
                            
                            // Answer text
                            Text(option)
                                .font(.system(size: 32, weight: .regular, design: .default))
                                .foregroundColor(textColor(for: option))
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .disabled(isAnswered)
                }
            }
            .padding(.horizontal)

            
            Spacer().frame(height: 20)
            
            // Next button - fully clickable
            Button {
                cancelAutoAdvance()
                goToNextQuestion()
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAnswered ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!isAnswered)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: Loading View
    
    var loadingView: some View {
        VStack {
            Spacer()
            
            Text("Calculating Results...")
                .font(.headline)
                .padding(.bottom, 30)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                Circle()
                    .trim(from: 0.0, to: loadingProgress)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.accentColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.easeInOut, value: loadingProgress)
            }
            .frame(width: 100, height: 100)
            
            Spacer()
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    // MARK: Summary View
    
    var summaryView: some View {
        SummaryView(
            score: score,
            total: questions.count,
            questions: questions,
            outcomes: outcomes,
            onPlayAgain: {
                questions = generateQuestions(count: questions.count)
                currentQuestionIndex = 0
                score = 0
                outcomes = Array(repeating: nil, count: questions.count)
                gamePhase = .question
            },
            onExit: resetGame
        )
    }

    
    // MARK: - Game Logic Functions
    
    /// Called when an answer option is tapped.
    func answerTapped(option: String) {
        selectedAnswer = option
        isAnswered = true
        
        outcomes[currentQuestionIndex] = (option == questions[currentQuestionIndex].correctAnswer)
        
        let feedback = UINotificationFeedbackGenerator()
        let currentQuestion = questions[currentQuestionIndex]
        
        if option == currentQuestion.correctAnswer {
            score += 1
            feedback.notificationOccurred(.success)
            
            // Cancel any existing dispatch
            cancelAutoAdvance()
            
            // Schedule auto-advance in 3 secs
            let workItem = DispatchWorkItem {
                goToNextQuestion()
            }
            autoAdvanceTask = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        } else {
            feedback.notificationOccurred(.error)
        }
    }
    
    /// Cancels any pending auto-advance so we don't double advance.
    func cancelAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
    }
    
    /// Resets the game back to the splash screen.
    func resetGame() {
        cancelAutoAdvance()
        loadingTimer?.invalidate()
        loadingTimer = nil
        gamePhase = .splash
        questions = []
        currentQuestionIndex = 0
        score = 0
        outcomes = []
    }
    
    /// Moves to the next question or ends the game.
    func goToNextQuestion() {
        isAnswered = false
        selectedAnswer = nil
        
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            // Show loading screen instead of directly going to summary
            gamePhase = .loading
        }
    }
    
    /// Starts the loading animation before showing the summary screen
    func startLoadingAnimation() {
        loadingProgress = 0
        
        // Cancel any existing timer
        loadingTimer?.invalidate()
        
        // Create a new timer that updates the progress
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                loadingProgress += 0.03
                
                // When loading is complete, show the summary
                if loadingProgress >= 1.0 {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        gamePhase = .summary
                    }
                }
            }
        }
    }
    
    /// Generates an array of QuizQuestion items.
    func generateQuestions(count: Int) -> [QuizQuestion] {
        var qs: [QuizQuestion] = []
        for _ in 0..<count {
            guard let letter = paleoLetters.randomElement() else { continue }
            let type: QuestionType = Bool.random() ? .paleoToModern : .modernToPaleo
            let correctAnswer = (type == .paleoToModern) ? letter.modern : letter.paleo
            
            // Generate three unique distractor answers.
            var distractors: [String] = []
            while distractors.count < 3 {
                guard let candidate = paleoLetters.randomElement() else { continue }
                let candidateAnswer = (type == .paleoToModern) ? candidate.modern : candidate.paleo
                if candidateAnswer != correctAnswer && !distractors.contains(candidateAnswer) {
                    distractors.append(candidateAnswer)
                }
            }
            var options = distractors + [correctAnswer]
            options.shuffle()
            
            let question = QuizQuestion(
                letter: letter,
                questionType: type,
                options: options,
                correctAnswer: correctAnswer
            )
            qs.append(question)
        }
        return qs
    }
    
    /// Returns color for each answer button based on user's selection & correctness.
    private func buttonColor(for option: String) -> Color {
        if !isAnswered {
            return Color(UIColor.systemGray5)
        }

        let currentQuestion = questions[currentQuestionIndex]

        if option == currentQuestion.correctAnswer {
            return Color.green.opacity(1)
        }

        if option == selectedAnswer && option != currentQuestion.correctAnswer {
            return Color.red.opacity(1)
        }

        return Color(UIColor.systemGray5)
    }
    
    private func textColor(for option: String) -> Color {
        guard isAnswered else { return .primary }

        let currentQuestion = questions[currentQuestionIndex]
        if option == currentQuestion.correctAnswer {
            return .white
        }
        if option == selectedAnswer && option != currentQuestion.correctAnswer {
            return .white
        }
        return .primary
    }
    
    private func colorForProgress(at index: Int) -> Color {
        if index < outcomes.count, let outcome = outcomes[index] {
            return outcome ? Color.green : Color.red
        } else {
            return index == currentQuestionIndex
                ? Color(UIColor.systemGray3)
                : Color(UIColor.systemGray4)
        }
    }
    
    private func outlineColor(for option: String) -> Color {
        if option == selectedAnswer {
            return .accentColor
        }
        return .gray
    }
}


#Preview {
    GameView()
}
