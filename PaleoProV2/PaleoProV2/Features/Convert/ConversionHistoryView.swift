import SwiftUI
import SwiftData

/// Past conversions, newest first. Tap one to load it back into the converter;
/// swipe to delete. Modeled on the Saved-Lines / History patterns from Speak
/// and Vocabulary.
struct ConversionHistoryView: View {
    /// Called with (source, modernToPaleo) when a row is tapped.
    var onPick: (String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \ConversionRecord.date, order: .reverse) private var records: [ConversionRecord]
    @State private var search = ""
    @State private var confirmClear = false

    private var filtered: [ConversionRecord] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return records }
        return records.filter { $0.source.localizedCaseInsensitiveContains(q) || $0.result.contains(q) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { record in
                            Button { pick(record) } label: { row(record) }
                                .tint(.primary)
                        }
                        .onDelete(perform: delete)
                    }
                    .searchable(text: $search, prompt: "Search conversions")
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
            .confirmationDialog("Clear all conversion history?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear History", role: .destructive, action: clearAll)
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private func row(_ record: ConversionRecord) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(record.result)
                .font(.system(size: 22))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.layoutDirection, .rightToLeft)
            Text(record.source)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: Spacing.xs) {
                Text("No History Yet")
                    .font(.title2.weight(.semibold))
                Text("Your conversions are saved here automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }

    private func pick(_ record: ConversionRecord) {
        onPick(record.source, record.modernToPaleo)
        Haptics.impact(.light)
        dismiss()
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(filtered[i]) }
        try? context.save()
    }

    private func clearAll() {
        for record in records { context.delete(record) }
        try? context.save()
        Haptics.warning()
    }
}
