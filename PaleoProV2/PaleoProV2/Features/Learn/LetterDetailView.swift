import SwiftUI

/// Bottom sheet shown when a letter is tapped in Learn. Modern + Paleo big at
/// the top, a quick copy, and a "Through the ages" timeline. Swipe left/right
/// (or tap the arrows) to move between letters.
struct LetterSheet: View {
    let start: PaleoLetter

    @State private var index: Int
    @State private var toast: ToastState?
    @AppStorage("learn.timelineShowAll") private var showAll = false
    @Environment(\.dismiss) private var dismiss

    init(start: PaleoLetter) {
        self.start = start
        _index = State(initialValue: Alphabet.letters.firstIndex(of: start) ?? 0)
    }

    private var letter: PaleoLetter { Alphabet.letters[index] }

    /// The evolution nodes: a curated (or full) run of datable scripts, ending
    /// at the modern Hebrew letter so the morph reads all the way to today.
    private var nodes: [TimelineNode] {
        let scripts = showAll ? ScribalFonts.timelineAll : ScribalFonts.timelineDefault
        // The Aramaic (Elephantine) node now shows the real transition toward
        // the square script, so the lineage tells itself.
        return scripts.map { .script($0) } + [.modern]
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)
            timeline
        }
        .toast($toast)
    }

    // MARK: Header (fixed)

    private var header: some View {
        VStack(spacing: Spacing.lg) {
            // A paging TabView so the letters follow your finger as you swipe
            // and snap on release; arrows are overlaid on the edges.
            ZStack {
                TabView(selection: $index) {
                    ForEach(Alphabet.letters.indices, id: \.self) { i in
                        pairing(Alphabet.letters[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 150)
                .onChange(of: index) { _, _ in Haptics.select() }

                HStack {
                    arrow("chevron.left") { step(-1) }
                    Spacer()
                    arrow("chevron.right") { step(1) }
                }
            }

            copyButton
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func pairing(_ l: PaleoLetter) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xl) {
                PaleoGlyph(text: l.paleo, size: 84)
                    .foregroundStyle(.tint)
                Text(l.modern)
                    .font(.system(size: 84))
            }
            .frame(height: 104)
            Text(l.name)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func arrow(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var copyButton: some View {
        Button {
            Clipboard.copy(letter.paleo)
            Haptics.impact(.medium)
            withAnimation(.smooth(duration: 0.25)) { toast = ToastState(content: letter.paleo) }
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .foregroundStyle(Color.onAccent)
    }

    // MARK: Timeline

    private var timeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("How it became Hebrew")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    // Plain blue text — deliberately understated; the default
                    // curated view is the point, this is just an optional reveal.
                    Button(showAll ? "Show less" : "Show more") {
                        withAnimation(.smooth) { showAll.toggle() }
                    }
                    .font(.subheadline)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
                .padding(.bottom, Spacing.md)

                ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                    TimelineRow(
                        node: node,
                        modern: letter.modern,
                        isFirst: i == 0,
                        isLast: i == nodes.count - 1,
                        // Cascade the reveal top-to-bottom; only newly inserted
                        // rows animate (rows already on screen don't re-appear).
                        appearDelay: Double(i) * 0.035
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 40)
        }
    }

    // MARK: Navigation

    private func step(_ delta: Int) {
        let count = Alphabet.letters.count
        withAnimation(.smooth(duration: 0.3)) {
            index = (index + delta + count) % count
        }
    }
}

/// A node in the evolution timeline: a datable script, or the modern endpoint.
enum TimelineNode: Identifiable {
    case script(ScribalFont)
    case modern

    var id: String {
        switch self {
        case .script(let f): return f.id
        case .modern: return "modern"
        }
    }
}

/// One node: a rail dot + the letter (in that script, or modern) + name and era.
/// The rail/line is always present (so it "makes the place" the moment a row
/// inserts), then the dot pops in, then the glyph + text fill in — each at
/// `appearDelay`, so a run of inserted rows cascades.
private struct TimelineRow: View {
    let node: TimelineNode
    let modern: String
    let isFirst: Bool
    let isLast: Bool
    var appearDelay: Double = 0

    @State private var shown = false
    @State private var showInfo = false

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            railColumn
            glyph
                .frame(width: 56, height: 56)
                .foregroundStyle(.primary)
                .opacity(shown ? 1 : 0)
                .animation(.smooth(duration: 0.25).delay(appearDelay + 0.06), value: shown)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(era).font(.caption).foregroundStyle(.secondary)
            }
            .opacity(shown ? 1 : 0)
            .animation(.smooth(duration: 0.25).delay(appearDelay + 0.06), value: shown)
            Spacer(minLength: 0)
            if hasNote {
                infoButton
                    .opacity(shown ? 1 : 0)
                    .animation(.smooth(duration: 0.25).delay(appearDelay + 0.06), value: shown)
            }
        }
        .frame(minHeight: 64)
        .onAppear { shown = true }
    }

    private var infoButton: some View {
        Button { showInfo = true } label: {
            Image(systemName: "eye")
                .font(.subheadline)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showInfo, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title).font(.headline)
                Text(noteText).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 280)
            .presentationCompactAdaptation(.popover)
        }
    }

    private var railColumn: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle().fill(railColor).frame(width: 2).opacity(isFirst ? 0 : 1)
                Rectangle().fill(railColor).frame(width: 2).opacity(isLast ? 0 : 1)
            }
            Circle()
                .fill(dotColor)
                .frame(width: isModern ? 12 : 9, height: isModern ? 12 : 9)
                .scaleEffect(shown ? 1 : 0.2)
                .opacity(shown ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(appearDelay), value: shown)
        }
        .frame(width: 14)
    }

    private var hasNote: Bool {
        if case .script(let f) = node { return !f.note.isEmpty }
        return false
    }
    private var noteText: String {
        if case .script(let f) = node { return f.note }
        return ""
    }

    @ViewBuilder
    private var glyph: some View {
        switch node {
        case .script(let f):
            // Culmus fonts are keyed on the Hebrew Unicode range, so feed the
            // modern letter; the font draws that era's shape.
            Text(modern).font(.custom(f.postScriptName, size: 40))
        case .modern:
            Text(modern).font(.system(size: 40, weight: .semibold)).foregroundStyle(.tint)
        }
    }

    private var isModern: Bool { if case .modern = node { return true }; return false }

    private var title: String {
        switch node {
        case .script(let f): return f.displayName
        case .modern: return "Modern Hebrew"
        }
    }

    private var era: String {
        switch node {
        case .script(let f): return f.era
        case .modern: return "today"
        }
    }

    private var dotColor: Color {
        switch node {
        case .modern: return .accentColor
        case .script(let f): return f.isAncientHand ? .accentColor : .secondary
        }
    }

    private var railColor: Color { Color.secondary.opacity(0.25) }
}

#Preview {
    LetterSheet(start: Alphabet.letters[1])
        .presentationDetents([.medium, .large])
}
