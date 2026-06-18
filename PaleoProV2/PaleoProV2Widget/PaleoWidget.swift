import WidgetKit
import SwiftUI
import CoreText
import AppIntents

// MARK: - Letter of the Day

struct LetterEntry: TimelineEntry {
    let date: Date
    let letter: PaleoLetter
}

struct LetterProvider: TimelineProvider {
    func placeholder(in context: Context) -> LetterEntry {
        LetterEntry(date: .now, letter: Alphabet.letterOfTheDay)
    }
    func getSnapshot(in context: Context, completion: @escaping (LetterEntry) -> Void) {
        completion(LetterEntry(date: .now, letter: Alphabet.letterOfTheDay))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LetterEntry>) -> Void) {
        let cal = Calendar.current
        let entries: [LetterEntry] = (0..<10).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: .now)) else { return nil }
            let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
            return LetterEntry(date: date, letter: Alphabet.letters[(day - 1) % Alphabet.letters.count])
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Fonts & brand color

/// Register all the bundled Culmus fonts once so every historical hand renders
/// (the system has no Paleo font; these are keyed on the modern Hebrew letter).
private let fontsReady: Bool = { ScribalFonts.registerAll(); return true }()

private func paleoFont(_ size: CGFloat) -> Font {
    _ = fontsReady
    return .custom("Hebrew-Paleo-Siloam", size: size)
}

/// Brand teal, set explicitly: the widget target's AccentColor handles system
/// chrome, but in-content color is set directly to stay exact in both schemes.
private let brandTeal = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 0.317, green: 0.859, blue: 0.872, alpha: 1)
        : UIColor(red: 0.0, green: 0.621, blue: 0.745, alpha: 1)
})

// MARK: - Evolution helpers (shared by the medium & large widgets)

private enum Evo { case script(ScribalFont); case modern }

private func evoNodes(_ fonts: [ScribalFont]) -> [Evo] { fonts.map { .script($0) } + [.modern] }

@ViewBuilder
private func evoGlyph(_ node: Evo, modern: String, size: CGFloat) -> some View {
    switch node {
    case .script(let f): Text(modern).font(.custom(f.postScriptName, size: size))
    case .modern: Text(modern).font(.system(size: size, weight: .semibold)).foregroundStyle(brandTeal)
    }
}

private func evoTitle(_ node: Evo) -> String {
    switch node { case .script(let f): return f.displayName; case .modern: return "Modern Hebrew" }
}

private func evoEra(_ node: Evo) -> String {
    switch node { case .script(let f): return f.era; case .modern: return "today" }
}

// MARK: - Views

struct LetterWidgetView: View {
    let entry: LetterEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.letter.name) · \(entry.letter.modern)")
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Text(entry.letter.modern).font(paleoFont(34))
                VStack(alignment: .leading) {
                    Text("Letter of the Day").font(.caption2).foregroundStyle(.secondary)
                    Text(entry.letter.name).font(.headline)
                }
            }
        case .systemMedium:
            mediumEvolution
        case .systemLarge:
            largeHistory
        default:
            smallLetter
        }
    }

    // systemSmall — a single bold glyph.
    private var smallLetter: some View {
        VStack(spacing: 4) {
            Text("Letter of the Day")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(entry.letter.modern)
                .font(paleoFont(64))
                .foregroundStyle(brandTeal)
            Spacer(minLength: 0)
            Text(entry.letter.name).font(.headline)
            Text(entry.letter.modern).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // systemMedium — the letter morphing across the scripts, left to right.
    private var mediumEvolution: some View {
        let nodes = evoNodes(ScribalFonts.timelineDefault)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.letter.name).font(.headline)
                Spacer()
                Text("How it became Hebrew").font(.caption2).foregroundStyle(.secondary)
            }
            // The glyph row expands to fill the height so the widget isn't
            // loose at the top and bottom.
            HStack(spacing: 2) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { i, node in
                    evoGlyph(node, modern: entry.letter.modern, size: 30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if i < nodes.count - 1 {
                        Image(systemName: "chevron.compact.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            HStack {
                Text(nodes.first.map { evoEra($0) } ?? "").font(.system(size: 9)).foregroundStyle(.tertiary)
                Spacer()
                Text("today").font(.system(size: 9)).foregroundStyle(.tertiary)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // systemLarge — the curated lineage, distributed to fill the (square)
    // widget and ending visibly at modern Hebrew. (timelineAll was far too tall
    // for this aspect ratio and clipped.)
    private var largeHistory: some View {
        let nodes = evoNodes(ScribalFonts.timelineDefault)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(entry.letter.modern)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(brandTeal)
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.letter.name).font(.title3.weight(.semibold))
                    Text("How it became Hebrew").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            VStack(spacing: 0) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { i, node in
                    HStack(spacing: 14) {
                        evoGlyph(node, modern: entry.letter.modern, size: 26)
                            .frame(width: 38, alignment: .center)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(evoTitle(node))
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text(evoEra(node)).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    if i < nodes.count - 1 { Spacer(minLength: 0) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct LetterOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PaleoLetterOfDay", provider: LetterProvider()) { entry in
            LetterWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Letter of the Day")
        .description("A Paleo-Hebrew letter and how it became modern Hebrew.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Control Center control (iOS 18+)

/// Opens the app to the converter. Routes via the App Group (the widget target
/// can't see the app's navigation), which the app reads on launch.
struct OpenConverterIntent: AppIntent {
    static var title: LocalizedStringResource = "Convert in Paleo Pro"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.com.d7mtg.PaleoHebrew")?.set("convert", forKey: "pendingRoute")
        return .result()
    }
}

struct ConvertControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "PaleoConvertControl") {
            ControlWidgetButton(action: OpenConverterIntent()) {
                Label("Convert", systemImage: "arrow.left.arrow.right")
            }
        }
        .displayName("Convert to Paleo")
        .description("Open the Paleo-Hebrew converter.")
    }
}

// MARK: - Quick-open sections widget

/// Opens the app to a section. Routes via the App Group (the widget can't see
/// the app's navigation); RootView reads `pendingRoute` on launch. Hidden from
/// Shortcuts since it only backs the widget tiles.
struct OpenSectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Paleo Pro Section"
    static var openAppWhenRun = true
    static var isDiscoverable = false

    @Parameter(title: "Section") var section: String
    init() {}
    init(_ section: String) { self.section = section }

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.com.d7mtg.PaleoHebrew")?.set(section, forKey: "pendingRoute")
        return .result()
    }
}

struct SectionsEntry: TimelineEntry { let date: Date }

struct SectionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SectionsEntry { SectionsEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (SectionsEntry) -> Void) {
        completion(SectionsEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SectionsEntry>) -> Void) {
        completion(Timeline(entries: [SectionsEntry(date: .now)], policy: .never))
    }
}

struct SectionsWidgetView: View {
    private let sections: [(title: String, symbol: String, route: String)] = [
        ("Learn", "book.closed", "learn"),
        ("Play", "gamecontroller", "play"),
        ("Convert", "arrow.left.arrow.right", "convert")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paleo Pro").font(.headline)
            HStack(spacing: 10) {
                ForEach(sections, id: \.route) { s in
                    Button(intent: OpenSectionIntent(s.route)) {
                        VStack(spacing: 6) {
                            Image(systemName: s.symbol)
                                .font(.title2)
                                .foregroundStyle(brandTeal)
                            Text(s.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

struct SectionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PaleoSections", provider: SectionsProvider()) { _ in
            SectionsWidgetView()
                .containerBackground(.fill.quaternary, for: .widget)
        }
        .configurationDisplayName("Quick Open")
        .description("Jump straight to Learn, Play, or Convert.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Bundle

@main
struct PaleoWidgets: WidgetBundle {
    var body: some Widget {
        LetterOfDayWidget()
        SectionsWidget()
        ConvertControl()
    }
}
