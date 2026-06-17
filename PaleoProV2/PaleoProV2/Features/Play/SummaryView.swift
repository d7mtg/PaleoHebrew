import SwiftUI
import SwiftData

struct SummaryView: View {
    let engine: QuizEngine

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var saved = false
    @State private var showConfetti = false
    @State private var confettiID = UUID()

    var body: some View {
        ZStack {
            QuizResultLayout(
                title: title,
                date: nil,
                score: engine.score,
                total: engine.total,
                outcomes: engine.outcomes,
                bottomBar: {
                    AnyView(actionButtons)
                }
            )

            if showConfetti {
                ConfettiView().id(confettiID)
            }
        }
        .task { persistOnce() }
    }

    // Primary action + Done, matching the pattern Apple uses on end-of-activity
    // screens (Fitness, Game Center). History lives on the Play start screen, so
    // it isn't duplicated here.
    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Haptics.impact(.light)
                engine.start()
            } label: {
                Label(primaryTitle, systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .foregroundStyle(Color.onAccent)

            Button {
                Haptics.impact(.rigid)
                engine.reset()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }

    private var title: String {
        switch engine.percent {
        case 0.9...: return "Excellent!"
        case 0.7..<0.9: return "Well Done"
        case 0.5..<0.7: return "Good Job"
        default: return "Keep Practicing"
        }
    }

    private var primaryTitle: String {
        switch engine.percent {
        case 0.8...: return "Play Again"
        case 0.5..<0.8: return "Try Again"
        default: return "Practice More"
        }
    }

    private func persistOnce() {
        guard !saved else { return }
        saved = true

        context.insert(QuizRecord(date: .now, score: engine.score, total: engine.total, outcomes: engine.outcomes))

        for outcome in engine.outcomes {
            let key = outcome.pairKey
            let descriptor = FetchDescriptor<LetterStat>(predicate: #Predicate { $0.pairKey == key })
            let stat: LetterStat
            if let existing = try? context.fetch(descriptor).first {
                stat = existing
            } else {
                stat = LetterStat(pairKey: key, name: outcome.name)
                context.insert(stat)
            }
            stat.total += 1
            if outcome.isCorrect { stat.correct += 1 }
        }
        try? context.save()

        ReviewCoordinator.recordQuizFinished(percent: engine.percent)

        if engine.percent >= 0.7 && !reduceMotion {
            Haptics.success()
            confettiID = UUID()
            withAnimation { showConfetti = true }
        }
    }
}

// MARK: - Shared layout for the live summary and any saved-record detail view

struct QuizResultLayout: View {
    let title: String
    let date: Date?
    let score: Int
    let total: Int
    let outcomes: [LetterOutcome]
    let bottomBar: () -> AnyView

    private var percent: Double { total > 0 ? Double(score) / Double(total) : 0 }

    private var ringColor: Color {
        switch percent {
        case 0.9...: return .green
        case 0.7..<0.9: return .blue
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                resultsList
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 60)
        }
        // Fill the whole screen, including under the home indicator, so nothing
        // shows through the bottom.
        .background(Color.appBackground.ignoresSafeArea())
        // The buttons sit in a bottom safe-area inset, so the scroll content
        // insets correctly and never hides behind them. The fade-up blur is the
        // inset's background and bleeds through the home-indicator area.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar()
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                .background(alignment: .bottom) {
                    FadeUpBlur()
                        .frame(height: 260)
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)
                }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            ZStack {
                Circle().stroke(Color.trackFill, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 52, weight: .bold))
                        .monospacedDigit()
                    Text("of \(total)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 168, height: 168)
            .padding(.top, Spacing.sm)

            if let date {
                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(percent, format: .percent.precision(.fractionLength(0)))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var resultsList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(outcomes.enumerated()), id: \.offset) { _, outcome in
                SummaryRow(outcome: outcome)
            }
        }
    }
}

/// A vertical fade-up blur: thin material that eases in from clear at the top
/// to a fully blurred surface at the bottom. Multiple gradient stops smooth
/// the start; the view extends through the bottom safe area so there's no
/// visible boundary at the device edge.
struct FadeUpBlur: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .background(.thinMaterial)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                 location: 0.00),
                        .init(color: .black.opacity(0.08),   location: 0.20),
                        .init(color: .black.opacity(0.30),   location: 0.45),
                        .init(color: .black.opacity(0.65),   location: 0.70),
                        .init(color: .black,                 location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }
}

private struct SummaryRow: View {
    let outcome: LetterOutcome

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: outcome.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.white, outcome.isCorrect ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(outcome.name).font(.headline)
                Text(outcome.promptWasPaleo ? "Paleo → Modern" : "Modern → Paleo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if outcome.isCorrect {
                Text(outcome.correctAnswer).font(.title2)
            } else {
                HStack(spacing: Spacing.xs) {
                    Text(outcome.picked ?? "·")
                        .foregroundStyle(.red)
                        .strikethrough()
                    Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                    Text(outcome.correctAnswer).foregroundStyle(.green)
                }
                .font(.title3)
            }
        }
        .padding(Spacing.md)
        .cardSurface()
    }
}
