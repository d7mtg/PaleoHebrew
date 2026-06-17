import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \QuizRecord.date, order: .reverse) private var records: [QuizRecord]
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(records) { record in
                            NavigationLink {
                                QuizDetailView(record: record)
                            } label: {
                                HistoryRow(record: record)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if !records.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear", role: .destructive) { confirmClear = true }
                    }
                }
            }
            .confirmationDialog("Clear all quiz history?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear History", role: .destructive, action: clearAll)
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: Spacing.xs) {
                Text("No Quiz History")
                    .font(.title2.weight(.semibold))
                Text("Finish a quiz and your results will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Start a Quiz")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .foregroundStyle(Color.onAccent)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
    }

    private func clearAll() {
        for record in records { context.delete(record) }
        try? context.save()
        Haptics.warning()
    }
}

private struct HistoryRow: View {
    let record: QuizRecord

    var body: some View {
        HStack(spacing: Spacing.lg) {
            PercentRing(percent: record.percent)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(record.score) out of \(record.total) correct")
                    .font(.headline)
                Text(record.date, format: .dateTime.month().day().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct PercentRing: View {
    let percent: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.trackFill, lineWidth: 4)
            Circle()
                .trim(from: 0, to: percent)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(percent, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: 11, weight: .bold))
                .monospacedDigit()
        }
    }

    private var color: Color {
        switch percent {
        case 0.9...: return .green
        case 0.7..<0.9: return .blue
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

/// Reuses `QuizResultLayout` so a saved history entry has the same shape as
/// the live end-of-quiz summary screen.
struct QuizDetailView: View {
    let record: QuizRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        QuizResultLayout(
            title: title,
            date: record.date,
            score: record.score,
            total: record.total,
            outcomes: record.outcomes
        ) {
            AnyView(
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .foregroundStyle(Color.onAccent)
            )
        }
        .navigationTitle("Quiz")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var title: String {
        switch record.percent {
        case 0.9...: return "Excellent!"
        case 0.7..<0.9: return "Well Done"
        case 0.5..<0.7: return "Good Job"
        default: return "Keep Practicing"
        }
    }
}
