import SwiftUI
import SwiftData

struct ConvertView: View {
    @AppStorage("convert.modernToPaleo") private var modernToPaleo = true
    @AppStorage("convert.stripNiqqud") private var stripNiqqud = true
    @AppStorage("convert.spacesAsDots") private var spacesAsDots = false
    @AppStorage("convert.autoFinal") private var autoFinal = true
    @AppStorage("convert.cleanInscription") private var cleanInscription = false

    @AppStorage(PaleoFontPreference.key, store: PaleoFontPreference.store) private var fontID = ""

    @Environment(\.modelContext) private var context
    @State private var input = ""
    @State private var toast: ToastState?
    @State private var swapRotation = 0.0
    @State private var showHistory = false
    @State private var suppressAutosave = false
    @FocusState private var focused: Bool

    /// Changing input or direction restarts the debounce, so a conversion is
    /// saved ~1.2s after you stop, whether or not you copy it.
    private var autosaveKey: String { "\(modernToPaleo)|\(input)" }

    /// The chosen letterform (nil = default Unicode Paleo).
    private var scribalFont: ScribalFont? {
        fontID.isEmpty ? nil : ScribalFonts.font(id: fontID)
    }

    /// When the output is Paleo and a scribal font is chosen, show it in that
    /// font (rendering the modern-Hebrew equivalent it's keyed on). Copy still
    /// uses the real Paleo Unicode `output`.
    private var outputIsPaleo: Bool {
        output.unicodeScalars.contains(where: Alphabet.isPaleoScalar)
    }
    private var useScribal: Bool { scribalFont != nil && outputIsPaleo }
    private var outputDisplay: String { useScribal ? ScribalFonts.modernText(for: output) : output }
    private var outputFont: Font {
        if useScribal, let f = scribalFont { return .custom(f.postScriptName, size: 30) }
        return .system(size: 30)
    }
    /// The input field follows the chosen letterform too (the Culmus fonts are
    /// keyed on Hebrew letters, so typed Hebrew shows in that ancient hand).
    private var inputFont: Font {
        if let f = scribalFont { return .custom(f.postScriptName, size: 30) }
        return .system(size: 30)
    }

    private var output: String {
        ConversionEngine.convert(
            input,
            modernToPaleo: modernToPaleo,
            options: .init(
                stripNiqqud: stripNiqqud,
                spacesAsDots: spacesAsDots,
                autoFinal: autoFinal,
                cleanInscription: cleanInscription
            )
        )
    }

    private var sourceLabel: String { modernToPaleo ? "Modern Hebrew" : "Paleo Hebrew" }
    private var targetLabel: String { modernToPaleo ? "Paleo Hebrew" : "Modern Hebrew" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    inputCard
                    swapButton
                    outputCard
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground)
            .navigationTitle("Convert")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .principal) {
                    Picker("Direction", selection: $modernToPaleo) {
                        Text("Modern → Paleo").tag(true)
                        Text("Paleo → Modern").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                #endif
                ToolbarItem(placement: .cancellationAction) {
                    Button { newConversion() } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New conversion")
                    .disabled(input.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }
                ToolbarItem(placement: .primaryAction) { optionsMenu }
                #if !os(macOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                        .fontWeight(.semibold)
                }
                #endif
            }
            .toast($toast)
            .task(id: autosaveKey) { await autosave() }
            .sheet(isPresented: $showHistory) {
                ConversionHistoryView { source, direction in
                    suppressAutosave = true      // loading an old entry shouldn't re-save it
                    modernToPaleo = direction
                    input = source
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
            }
        }
    }

    /// Debounced: waits for a pause, then saves the current conversion.
    private func autosave() async {
        if suppressAutosave { suppressAutosave = false; return }
        try? await Task.sleep(for: .seconds(1.2))
        guard !Task.isCancelled else { return }
        saveToHistory()
    }

    private func newConversion() {
        suppressAutosave = true
        withAnimation(Motion.smooth) { input = "" }
        focused = true
        Haptics.impact(.light)
    }

    // MARK: Input

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                Text(sourceLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !input.isEmpty {
                    Button { clear() } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("Clear")
                    .tint(.secondary)
                }
                if Clipboard.hasString {
                    Button { paste() } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline)
                    }
                }
            }
            .frame(height: 28) // reserve row height so action buttons don't shift the label
            TextField(text: $input, prompt: Text(inputPlaceholder), axis: .vertical) {
                EmptyView()
            }
            .font(inputFont)
            .lineLimit(3...)
            .focused($focused)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .cardSurface()
    }

    private var inputPlaceholder: String {
        modernToPaleo ? "אבג…" : "𐤀𐤁𐤂…"
    }

    private var outputPlaceholder: String {
        modernToPaleo ? "𐤀𐤁𐤂…" : "אבג…"
    }

    // MARK: Swap

    private var swapButton: some View {
        Button {
            swap()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.headline)
                .rotationEffect(.degrees(swapRotation))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .accessibilityLabel("Swap direction")
    }

    // MARK: Output

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                Text(targetLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Spacer()
                if !output.isEmpty {
                    Button { copy() } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
                    .foregroundStyle(Color.onAccent)
                }
            }
            .frame(height: 28) // reserve row height so the label doesn't shift when Copy appears
            if output.isEmpty {
                Text(outputPlaceholder)
                    .font(.system(size: 30))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, .rightToLeft)
            } else {
                Text(outputDisplay)
                    .font(outputFont)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, .rightToLeft)
                    .contentTransition(.interpolate)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .cardSurface()
        .animation(Motion.smooth, value: output)
    }

    // MARK: Options

    private var optionsMenu: some View {
        Menu {
            if modernToPaleo {
                Section("Modern → Paleo") {
                    Toggle("Remove vowel points", isOn: $stripNiqqud)
                    Toggle("Word-divider dots ·", isOn: $spacesAsDots)
                }
            } else {
                Section("Paleo → Modern") {
                    Toggle("Final letter forms", isOn: $autoFinal)
                    Toggle("Clean inscription marks", isOn: $cleanInscription)
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .accessibilityLabel("Conversion options")
    }

    // MARK: Actions

    private func swap() {
        let carried = output
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            modernToPaleo.toggle()
            input = carried
            swapRotation += 180
        }
        focused = false
        Haptics.impact(.medium)
    }

    private func copy() {
        Clipboard.copy(output)
        Haptics.success()
        ReviewCoordinator.recordCopy()
        saveToHistory()
        withAnimation(.smooth(duration: 0.3)) { toast = ToastState(content: output) }
    }

    /// Save the conversion the user just copied, skipping empties and exact
    /// repeats of the most recent entry.
    private func saveToHistory() {
        let src = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !src.isEmpty, !output.isEmpty else { return }
        var recent = FetchDescriptor<ConversionRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        recent.fetchLimit = 1
        if let last = try? context.fetch(recent).first,
           last.source == src, last.result == output, last.modernToPaleo == modernToPaleo {
            return
        }
        context.insert(ConversionRecord(date: .now, source: src, result: output, modernToPaleo: modernToPaleo))
        try? context.save()
    }

    private func paste() {
        guard let string = Clipboard.paste() else { return }
        input = string
        Haptics.impact(.light)
    }

    private func clear() {
        withAnimation(Motion.smooth) { input = "" }
        Haptics.impact(.light)
    }
}

#Preview {
    ConvertView()
}
