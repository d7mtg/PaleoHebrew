import SwiftUI

struct PlayView: View {
    @State private var engine = QuizEngine()
    @State private var showHistory = false
    @Environment(\.newQuizTrigger) private var newQuizTrigger

    var body: some View {
        ZStack {
            switch engine.phase {
            case .splash:
                SplashScreen(engine: engine, showHistory: $showHistory)
            case .question, .loading:
                QuestionScreen(engine: engine)
            case .summary:
                SummaryView(engine: engine)
            }
        }
        // Hide the tab bar during the quiz + summary so the bottom action bar
        // isn't covered by it. Restored on the splash screen. (Mac has no
        // tab bar in this hierarchy — it lives in a NavigationSplitView.)
        #if !os(macOS)
        .toolbar(engine.phase == .splash ? .visible : .hidden, for: .tabBar)
        #endif
        .animation(.smooth(duration: 0.4), value: engine.phase)
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
        }
        // Mac File → New Quiz starts a fresh quiz from any state.
        .onChange(of: newQuizTrigger) { _, _ in engine.start() }
    }
}

// MARK: - Splash

private struct SplashScreen: View {
    let engine: QuizEngine
    @Binding var showHistory: Bool
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Parallax field — fades to clear in the bottom third so it never
            // sits behind the call-to-action buttons.
            InteractiveBackground()
                .mask(
                    LinearGradient(
                        stops: [.init(color: .black, location: 0),
                                .init(color: .black, location: 0.55),
                                .init(color: .clear, location: 0.95)],
                        startPoint: .top, endPoint: .bottom)
                )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Image("AppIconMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 84)
                    .foregroundStyle(.tint)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.92)

                Text("Learn\nPaleo Hebrew")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.lg)

                Text("Master the ancient alphabet,\none letter at a time.")
                    .font(.headline.weight(.regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
                Spacer(minLength: 0)

                VStack(spacing: Spacing.md) {
                    Button {
                        Haptics.impact(.light)
                        engine.start()
                    } label: {
                        Label("Start Game", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.extraLarge)
                    .foregroundStyle(Color.onAccent)

                    Button {
                        showHistory = true
                    } label: {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .task {
            withAnimation(.smooth(duration: 0.5).delay(0.05)) { appeared = true }
        }
    }
}

// MARK: - Question

private struct QuestionScreen: View {
    let engine: QuizEngine

    var body: some View {
        VStack(spacing: Spacing.lg) {
            header
            ProgressStrip(results: engine.results, current: engine.index)
            Spacer(minLength: 0)
            promptCard
            Spacer(minLength: 0)
            if let q = engine.current {
                optionsGrid(q)
                    // Re-key on the question id so a repeating glyph never
                    // morphs from its previous position — each question starts
                    // its options fresh in place.
                    .id(q.id)
            }
            nextButton
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.lg)
        .background(Color.appBackground)
    }

    private var header: some View {
        ZStack {
            Text("\(engine.index + 1) of \(engine.total)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            HStack {
                Button {
                    Haptics.impact(.rigid)
                    engine.reset()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("End Quiz")
                Spacer()
            }
        }
    }

    private var promptCard: some View {
        PaleoGlyph(text: engine.current?.prompt ?? "", size: 150, weight: .bold)
            .minimumScaleFactor(0.5)
            .contentTransition(.opacity)
            .id(engine.current?.id)
    }

    private func optionsGrid(_ q: QuizEngine.Question) -> some View {
        let columns = [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)]
        return LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(q.options, id: \.self) { option in
                OptionButton(
                    glyph: option,
                    state: optionState(for: option, in: q),
                    answered: engine.isAnswered
                ) {
                    engine.answer(option)
                    if option == q.correct { Haptics.success() } else { Haptics.error() }
                }
            }
        }
    }

    private func optionState(for option: String, in q: QuizEngine.Question) -> OptionButton.State {
        guard engine.isAnswered else { return .idle }
        if option == q.correct { return .correct }
        if option == engine.picked { return .wrong }
        return .dimmed
    }

    private var nextButton: some View {
        Button {
            engine.next()
        } label: {
            Label(engine.index + 1 == engine.total ? "Finish" : "Next",
                  systemImage: "arrow.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .foregroundStyle(Color.onAccent)
        .disabled(!engine.isAnswered)
        .opacity(engine.isAnswered ? 1 : 0.5)
        .animation(Motion.smooth, value: engine.isAnswered)
    }
}

private struct OptionButton: View {
    enum State { case idle, correct, wrong, dimmed }

    let glyph: String
    let state: State
    let answered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                PaleoGlyph(text: glyph, size: 56)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                if state == .correct {
                    badge("checkmark.circle.fill", .green)
                } else if state == .wrong {
                    badge("xmark.circle.fill", .red)
                }
            }
            // Idle tiles are real glass; answered tiles take a colored tint.
            .glassEffect(.regular, in: .rect(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                if state == .correct || state == .wrong {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(state == .correct ? Color.green.opacity(0.22) : Color.red.opacity(0.22))
                }
            }
            .opacity(state == .dimmed ? 0.45 : 1)
        }
        .buttonStyle(.pressable)
        .disabled(answered)
        .animation(Motion.smooth, value: state)
    }

    private func badge(_ symbol: String, _ color: Color) -> some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(.white, color)
                    .padding(Spacing.sm)
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
        }
    }

}

private struct ProgressStrip: View {
    let results: [Bool?]
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(results.indices, id: \.self) { i in
                Capsule()
                    .fill(color(for: i))
                    .frame(height: 7)
            }
        }
        .animation(.smooth(duration: 0.3), value: results)
        .animation(.smooth(duration: 0.3), value: current)
    }

    private func color(for index: Int) -> Color {
        if let result = results[index] { return result ? .green : .red }
        return index == current ? .accentColor : Color.trackFill
    }
}
