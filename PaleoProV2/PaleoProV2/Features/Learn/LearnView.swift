import SwiftUI

/// The "Learn" tab. Two literal layouts (grid + list) live side-by-side in a
/// ZStack; `matchedGeometryEffect` ties each letter's grid tile to its list row
/// so SwiftUI interpolates frame + position when the toggle flips.
struct LearnView: View {
    @AppStorage("learn.isGrid") private var isGrid = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var toast: ToastState?
    @State private var query: String = ""
    @State private var sheetLetter: PaleoLetter?
    @Namespace private var morphNS

    private var matchingLetters: [PaleoLetter] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Alphabet.letters }
        let q = trimmed.lowercased()
        return Alphabet.letters.filter { letter in
            letter.name.lowercased().contains(q) ||
            letter.modern.contains(trimmed) ||
            letter.paleo.contains(trimmed)
        }
    }

    private var gridRows: [[PaleoLetter]] {
        let letters = matchingLetters
        return stride(from: 0, to: letters.count, by: 3).map {
            Array(letters[$0 ..< min($0 + 3, letters.count)])
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // The canonical SwiftUI list↔grid morph: only ONE branch is
                // ever in the hierarchy, the other is added/removed via the
                // if. matchedGeometryEffect interpolates each letter's frame
                // between the old branch's source and the new branch's source.
                ZStack(alignment: .top) {
                    if isGrid {
                        grid
                    } else {
                        list
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xs)
                .padding(.bottom, 110)
            }
            .background(Color.appBackground)
            .navigationTitle("Paleo Pro")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { layoutToggle }
            }
            .searchable(text: $query, placement: .toolbar, prompt: "Search letters")
            .toast($toast)
            .sheet(item: $sheetLetter) { letter in
                LetterSheet(start: letter)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
            }
            .task {
                // Debug-only: PREVIEW_LETTER=<name> auto-opens the sheet for screenshots.
                if let name = ProcessInfo.processInfo.environment["PREVIEW_LETTER"],
                   let l = Alphabet.letters.first(where: { $0.name.lowercased() == name.lowercased() }) {
                    sheetLetter = l
                }
            }
        }
    }

    // MARK: Two layouts that share matched-geometry IDs

    private var grid: some View {
        VStack(spacing: Spacing.md) {
            ForEach(Array(gridRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Spacing.md) {
                    ForEach(row) { letter in
                        gridTile(letter)
                            .matchedGeometryEffect(id: letter.id, in: morphNS)
                    }
                    ForEach(0 ..< (3 - row.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
    }

    private var list: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(matchingLetters) { letter in
                listRow(letter)
                    .matchedGeometryEffect(id: letter.id, in: morphNS)
            }
        }
    }

    private var layoutToggle: some View {
        Button {
            let anim: Animation = reduceMotion ? .linear(duration: 0.0001) : .smooth(duration: 0.5)
            withAnimation(anim) { isGrid.toggle() }
            Haptics.select()
        } label: {
            Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isGrid ? "Switch to list" : "Switch to grid")
    }

    // MARK: Tiles

    private func gridTile(_ letter: PaleoLetter) -> some View {
        Button { sheetLetter = letter } label: {
            VStack(spacing: Spacing.xs) {
                PaleoGlyph(text: letter.paleo, size: 46)
                    .frame(height: 52)
                Text(letter.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(letter.modern)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .cardSurface(Radius.card, fill: .cardFill)
        }
        .buttonStyle(.pressable)
        .contextMenu { menu(for: letter) }
        .accessibilityLabel("\(letter.name), \(letter.modern)")
    }

    private func listRow(_ letter: PaleoLetter) -> some View {
        Button { sheetLetter = letter } label: {
            HStack(spacing: Spacing.lg) {
                PaleoGlyph(text: letter.paleo, size: 34)
                    .frame(width: 50, alignment: .center)
                Text(letter.name)
                    .font(.headline)
                Spacer()
                Text(letter.modern)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(Radius.card, fill: .cardFill)
        }
        .buttonStyle(.pressable)
        .contextMenu { menu(for: letter) }
        .accessibilityLabel("\(letter.name), \(letter.modern)")
    }

    // MARK: Context menu

    @ViewBuilder
    private func menu(for letter: PaleoLetter) -> some View {
        Button { copy(letter.paleo) } label: {
            Label("Copy Paleo  \(letter.paleo)", systemImage: "doc.on.doc")
        }
        Button { copy(letter.modern) } label: {
            Label("Copy Modern  \(letter.modern)", systemImage: "doc.on.doc")
        }
        Menu {
            Button { copyUnicode(of: letter.modern) } label: {
                Label("Copy Unicode", systemImage: "number")
            }
            Button { copyHTMLEntity(of: letter.modern) } label: {
                Label("Copy HTML Entity", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } label: {
            Label("Advanced", systemImage: "ellipsis.circle")
        }
    }

    // MARK: Actions

    private func copy(_ value: String) {
        Clipboard.copy(value)
        Haptics.impact(.medium)
        ReviewCoordinator.recordCopy()
        withAnimation(.smooth(duration: 0.25)) { toast = ToastState(content: value) }
    }

    private func copyUnicode(of string: String) {
        guard let scalar = string.unicodeScalars.first else { return }
        copy(String(format: "U+%04X", scalar.value))
    }

    private func copyHTMLEntity(of string: String) {
        guard let scalar = string.unicodeScalars.first else { return }
        copy(String(format: "&#x%X;", scalar.value))
    }
}

#Preview { LearnView() }
