import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A blog-style page about Paleo-Hebrew. Academic but readable prose, selectable
/// text, full artifact images you can tap to zoom, copyable inscriptions, and
/// inline glossary terms (dotted underline, tap for a short definition).
struct AboutPaleoHebrewView: View {
    @State private var copyToast: ToastState?
    @State private var zoomedAsset: String?
    @State private var glossaryTerm: GlossaryEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                contents
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .navigationTitle("Learning Center")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toast($copyToast)
        // Intercept glossary:// links from inline terms and show a definition.
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "glossary",
                  let raw = url.host?.removingPercentEncoding,
                  let entry = Glossary.all[raw]
            else { return .systemAction }
            glossaryTerm = entry
            return .handled
        })
        .sheet(item: $glossaryTerm) { entry in
            GlossarySheet(entry: entry)
                .presentationDetents([.height(240), .medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
        }
        .fullScreenCover(item: zoomedBinding) { asset in
            ZoomableImageView(asset: asset.id)
        }
    }

    private var zoomedBinding: Binding<IdentifiedString?> {
        Binding(
            get: { zoomedAsset.map(IdentifiedString.init) },
            set: { zoomedAsset = $0?.id }
        )
    }

    @ViewBuilder
    private var contents: some View {
        hero
        lead
        heading("How the alphabet spread")
        ancestry
        heading("From Paleo to the square script")
        squareScript
        heading("The Siloam Inscription")
        siloam
        artifact(
            asset: "SiloamInscription",
            caption: "Siloam Inscription. Replica at the Israel Museum, Jerusalem; the original is in the Istanbul Archaeology Museum. Photo: Yael Y. (CC BY-SA 3.0).",
            paleoText: Inscriptions.siloam
        )
        heading("The Tel Dan Stele")
        telDan
        artifact(
            asset: "TelDanStele",
            caption: "Tel Dan Stele, Israel Museum, Jerusalem. Photo: Oren Rozen (CC BY-SA 4.0).",
            paleoText: Inscriptions.telDan
        )
        heading("The First Jewish War half shekel")
        jewishWarShekel
        artifact(
            asset: "JewishWarShekel",
            caption: "Silver half shekel of the First Jewish War (66 to 70 CE). Photo: Classical Numismatic Group (CC BY-SA 3.0).",
            paleoText: Inscriptions.halfShekel
        )
        heading("The full alphabet")
        Text("All 22 letters, aleph through tav. Tap Copy for the whole row.")
            .font(.body)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        alphabetRow
        heading("Where it lives in Unicode")
        unicode
        heading("Resources")
        resources
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            Text("𐤀𐤁𐤂𐤃𐤄𐤅")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("About Paleo-Hebrew")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Twenty-two letters, three thousand years")
                .font(.headline.weight(.regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    // MARK: Prose (academic tone, standard English names, no em dashes)

    private var lead: some View {
        para("""
        [[Paleo-Hebrew]] is the script in which Hebrew was first written. It appears in the early Israelite period and stayed in regular use through the [[First Temple]] period. Its 22 letters correspond one to one with the modern square Hebrew alphabet, so a verse written in Paleo reads exactly the same as the same verse in the square script. Only the shapes of the letters differ.
        """)
    }

    private var ancestry: some View {
        para("""
        Paleo-Hebrew belongs to the same family as the [[Phoenician]] alphabet used along the Levantine coast. From there the alphabet moved west: Greek adapted and reoriented the letters, Latin grew out of Greek, and most European scripts descend from that line. Letters as familiar as A and B began as forms like 𐤀 and 𐤁.
        """)
    }

    private var squareScript: some View {
        para("""
        After the [[Babylonian exile]], Jewish scribes gradually adopted the Aramaic square letterforms, known as [[Ktav Ashuri]], in place of the older Paleo shapes. By the Second Temple period the square script had become standard, and it is the script used for a Torah scroll, mezuzah, and tefillin to this day. The Talmud in tractate Sanhedrin (21b through 22a) records the discussion of which script the Torah was first given in.
        """)
    }

    private var siloam: some View {
        para("""
        Discovered in 1880 in [[Hezekiah's Tunnel]] beneath the City of David, the Siloam Inscription describes the moment two teams of workers, digging from opposite ends to carry water into Jerusalem, met in the middle and broke through the rock. Cut in the reign of King Hezekiah, it is one of the longest monumental Hebrew texts to survive from the First Temple period, and it is written entirely in Paleo-Hebrew.
        """)
    }

    private var telDan: some View {
        para("""
        Found in northern Israel in 1993, the Tel Dan [[Stele]] carries the phrase "House of David," the earliest reference to the dynasty of King David known outside the Bible. The inscription is in Aramaic, written in a script closely related to Paleo-Hebrew, which is why its letters read so clearly to anyone who knows the alphabet.
        """)
    }

    private var jewishWarShekel: some View {
        para("""
        During the First Jewish War against Rome (66 to 70 CE), the people of Jerusalem struck their own silver coins, reviving Paleo-Hebrew even though it had not been in daily use for centuries. The choice of the old script was deliberate, a claim of continuity with ancient Israel. On this half shekel one face shows a chalice with the legend "Half shekel"; the other shows three pomegranates with the legend "Jerusalem the Holy." These coins are among the last large-scale uses of Paleo-Hebrew.
        """)
    }

    private var unicode: some View {
        para("""
        Paleo-Hebrew is encoded in the Phoenician block of Unicode, U+10900 to U+1091F, within the [[Supplementary Multilingual Plane]]. Some older devices show empty boxes instead of the letters. Paleo Pro maps the characters internally, so the converter and keyboard work the same whether or not your device has a Paleo font.
        """)
    }

    // MARK: Resources

    private var resources: some View {
        VStack(alignment: .leading, spacing: 0) {
            resourceRow("The History of the Hebrew Script",
                        "https://culmus.sourceforge.io/ancient/HscriptPresent/Hebrew-Script.html",
                        wiki: false)
            divider
            resourceRow("Paleo-Hebrew alphabet", "https://en.wikipedia.org/wiki/Paleo-Hebrew_alphabet")
            divider
            resourceRow("Phoenician alphabet", "https://en.wikipedia.org/wiki/Phoenician_alphabet")
            divider
            resourceRow("Siloam Inscription", "https://en.wikipedia.org/wiki/Siloam_inscription")
            divider
            resourceRow("Tel Dan Stele", "https://en.wikipedia.org/wiki/Tel_Dan_stele")
            divider
            resourceRow("First Jewish Revolt coinage", "https://en.wikipedia.org/wiki/First_Jewish_Revolt_coinage")
        }
    }

    private var divider: some View { Divider().padding(.leading, 38) }

    private func resourceRow(_ title: String, _ url: String, wiki: Bool = true) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: Spacing.md) {
                if wiki {
                    WikipediaMark()
                } else {
                    Image(systemName: "text.book.closed")
                        .foregroundStyle(.tint)
                        .frame(width: 26, height: 26)
                }
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(.tertiary)
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: Building blocks

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .textSelection(.enabled)
            .padding(.top, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Body paragraph with `[[term]]` markers rendered as dotted-underline,
    /// tappable glossary terms.
    private func para(_ markup: String) -> some View {
        Text(Glossary.annotate(markup))
            .font(.body)
            .tint(.accentColor)
            .textSelection(.enabled)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Artifact card: full (uncropped) image, tappable to zoom, with a Copy
    /// button overlaid top-right and a one-line caption below.
    private func artifact(asset: String, caption: String, paleoText: String) -> some View {
        let paleo = paleoText
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if assetExists(asset) {
                        Button { zoomedAsset = asset } label: {
                            Image(asset)
                                .resizable()
                                .scaledToFit()              // full image, never cropped
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Color.cardFill)
                            .frame(height: 180)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo").font(.title).foregroundStyle(.tertiary)
                                    Text(asset).font(.caption2).foregroundStyle(.tertiary)
                                }
                            )
                    }
                }

                Button {
                    Clipboard.copy(paleo)
                    Haptics.impact(.medium)
                    withAnimation(.smooth(duration: 0.25)) { copyToast = ToastState(content: paleo) }
                } label: {
                    Label("Copy text", systemImage: "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glassProminent)
                .controlSize(.small)
                .foregroundStyle(Color.onAccent)
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xs)
    }

    /// The full alphabet — scrolls horizontally so the 22 wide glyphs can never
    /// push the page past the screen edge.
    private var alphabetRow: some View {
        let text = "𐤀𐤁𐤂𐤃𐤄𐤅𐤆𐤇𐤈𐤉𐤊𐤋𐤌𐤍𐤎𐤏𐤐𐤑𐤒𐤓𐤔𐤕"
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Aleph through Tav")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Clipboard.copy(text)
                    Haptics.impact(.medium)
                    withAnimation(.smooth(duration: 0.25)) { copyToast = ToastState(content: text) }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(size: 30))
                    .textSelection(.enabled)
                    .environment(\.layoutDirection, .rightToLeft)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Glossary

struct GlossaryEntry: Identifiable, Equatable {
    let id: String      // the term as written
    let definition: String
}

enum Glossary {
    /// term (as written between [[ ]]) → definition
    static let all: [String: GlossaryEntry] = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

    private static let entries: [GlossaryEntry] = [
        .init(id: "Paleo-Hebrew", definition: "The earliest script used to write Hebrew, in use through the First Temple period. Its 22 letters match the modern Hebrew alphabet one to one."),
        .init(id: "First Temple", definition: "The period of the First Temple in Jerusalem, roughly the 10th century BCE to 586 BCE."),
        .init(id: "Phoenician", definition: "The alphabet of the Phoenician city-states on the Levantine coast, closely related to Paleo-Hebrew and ancestral to the Greek and Latin alphabets."),
        .init(id: "Babylonian exile", definition: "The deportation of Judeans to Babylon after the destruction of the First Temple in 586 BCE."),
        .init(id: "Ktav Ashuri", definition: "The square Hebrew script adopted after the Babylonian exile. It is the script required for a Torah scroll, mezuzah, and tefillin."),
        .init(id: "Hezekiah's Tunnel", definition: "A water tunnel cut through bedrock beneath the City of David in the reign of King Hezekiah, to bring the Gihon spring's water inside the walls of Jerusalem."),
        .init(id: "Stele", definition: "An upright stone slab carved with an inscription, set up as a monument."),
        .init(id: "Supplementary Multilingual Plane", definition: "A range of Unicode beyond the common characters, holding historic scripts like Phoenician. Some older fonts do not include it."),
    ]

    /// Turn "text with [[term]] markers" into an AttributedString where each
    /// marked term gets a dotted underline and a glossary:// link.
    static func annotate(_ markup: String) -> AttributedString {
        var result = AttributedString()
        var rest = Substring(markup)
        while let open = rest.range(of: "[[") {
            result += AttributedString(String(rest[..<open.lowerBound]))
            let afterOpen = rest[open.upperBound...]
            guard let close = afterOpen.range(of: "]]") else {
                result += AttributedString("[[")
                rest = afterOpen
                continue
            }
            let term = String(afterOpen[..<close.lowerBound])
            var run = AttributedString(term)
            run.underlineStyle = Text.LineStyle(pattern: .dot, color: nil)
            if let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
               let url = URL(string: "glossary://\(encoded)") {
                run.link = url
            }
            result += run
            rest = afterOpen[close.upperBound...]
        }
        result += AttributedString(String(rest))
        return result
    }
}

private struct GlossarySheet: View {
    let entry: GlossaryEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(entry.id)
                    .font(.title2.weight(.bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(entry.definition)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inscription source text (modern Hebrew → converted to Paleo at runtime)

/// Paleo-Hebrew transcriptions, with the inscriptional word divider (U+1091F).
/// Bracketed/restored sections are not included; these are the read portions.
private enum Inscriptions {
    // The full Siloam Inscription.
    static let siloam =
    "𐤄𐤍𐤒𐤁𐤄𐤟𐤅𐤆𐤄𐤟𐤄𐤉𐤄𐤟𐤃𐤁𐤓𐤟𐤄𐤍𐤒𐤁𐤄𐤟𐤁𐤏𐤅𐤃𐤟𐤌𐤍𐤐𐤌𐤟𐤀𐤕𐤟𐤄𐤂𐤓𐤆𐤍𐤟𐤀𐤔𐤟𐤀𐤋𐤟𐤓𐤏𐤅𐤟𐤅𐤁𐤏𐤅𐤃𐤟𐤔𐤋𐤔𐤟𐤀𐤌𐤕𐤟𐤋𐤄𐤍𐤒𐤁𐤟𐤍𐤔𐤌𐤏𐤟𐤒𐤋𐤟𐤀𐤔𐤟𐤒𐤓𐤀𐤟𐤀𐤋𐤟𐤓𐤏𐤅𐤟𐤊𐤉𐤟𐤄𐤉𐤕𐤟𐤆𐤃𐤄𐤟𐤁𐤑𐤓𐤟𐤌𐤉𐤌𐤍𐤟𐤅𐤌𐤔𐤌𐤀𐤋𐤟𐤅𐤁𐤉𐤌𐤟𐤄𐤍𐤒𐤁𐤄𐤟𐤄𐤊𐤅𐤟𐤄𐤇𐤑𐤁𐤌𐤟𐤀𐤔𐤟𐤋𐤒𐤓𐤕𐤟𐤓𐤏𐤅𐤟𐤂𐤓𐤆𐤍𐤟𐤏𐤋𐤟𐤂𐤓𐤆𐤍𐤟𐤅𐤉𐤋𐤊𐤅𐤟𐤄𐤌𐤉𐤌𐤟𐤌𐤍𐤟𐤄𐤌𐤅𐤑𐤀𐤟𐤀𐤋𐤟𐤄𐤁𐤓𐤊𐤄𐤟𐤁𐤌𐤀𐤕𐤉𐤌𐤟𐤅𐤀𐤋𐤐𐤟𐤀𐤌𐤄𐤟𐤅𐤌𐤀𐤕𐤟𐤀𐤌𐤄𐤟𐤄𐤉𐤄𐤟𐤂𐤁𐤄𐤟𐤄𐤑𐤓𐤟𐤏𐤋𐤟𐤓𐤀𐤔𐤟𐤄𐤇𐤑𐤁𐤌"

    // The Tel Dan Stele (Biran & Naveh reading), line by line.
    static let telDan = [
        "𐤀𐤌𐤓𐤟𐤏𐤟𐤅𐤂𐤆𐤓",
        "𐤀𐤁𐤉𐤟𐤉𐤎𐤒𐤟𐤏𐤋𐤅𐤄𐤟𐤁𐤄𐤟𐤕𐤋𐤇𐤌𐤄𐤟𐤁𐤀",
        "𐤅𐤉𐤔𐤊𐤁𐤟𐤀𐤁𐤉𐤟𐤉𐤄𐤊𐤟𐤀𐤋𐤟𐤀𐤁𐤄𐤅𐤟𐤄𐤟𐤅𐤉𐤏𐤋𐤟𐤌𐤋𐤊𐤉𐤟𐤉𐤔",
        "𐤓𐤀𐤋𐤟𐤒𐤃𐤌𐤟𐤁𐤀𐤓𐤒𐤟𐤀𐤁𐤉𐤟𐤅𐤟𐤉𐤄𐤋𐤊𐤟𐤄𐤃𐤃𐤟𐤀𐤟𐤉𐤕𐤉",
        "𐤀𐤍𐤄𐤟𐤅𐤉𐤄𐤊𐤟𐤄𐤃𐤃𐤟𐤒𐤃𐤌𐤉𐤟𐤅𐤟𐤀𐤐𐤒𐤟𐤌𐤍𐤟𐤔𐤁𐤏𐤟𐤕",
        "𐤉𐤟𐤌𐤋𐤊𐤉𐤟𐤅𐤀𐤒𐤕𐤋𐤟𐤌𐤋𐤟𐤊𐤍𐤟𐤔𐤁𐤟𐤏𐤍𐤟𐤀𐤎𐤓𐤉𐤟𐤀𐤟𐤋𐤐𐤉𐤟𐤓",
        "𐤊𐤁𐤟𐤅𐤀𐤋𐤐𐤉𐤟𐤐𐤓𐤔𐤟𐤒𐤕𐤋𐤕𐤟𐤀𐤉𐤕𐤟𐤉𐤄𐤅𐤟𐤓𐤌𐤟𐤁𐤓𐤟𐤀𐤇𐤀𐤁",
        "𐤌𐤋𐤊𐤟𐤉𐤔𐤓𐤀𐤋𐤟𐤅𐤒𐤕𐤋𐤟𐤕𐤟𐤀𐤉𐤕𐤟𐤀𐤇𐤆𐤟𐤉𐤄𐤅𐤟𐤁𐤓𐤟𐤉𐤄𐤅𐤓𐤌𐤟𐤌𐤋",
        "𐤊𐤟𐤁𐤉𐤕𐤃𐤅𐤃𐤟𐤅𐤀𐤔𐤌𐤟𐤀𐤉𐤕𐤟𐤒𐤓𐤉𐤕𐤟𐤄𐤌𐤟𐤇𐤓𐤁𐤕𐤟𐤅𐤀𐤄𐤐𐤊𐤟𐤀",
        "𐤉𐤕𐤟𐤀𐤓𐤒𐤟𐤄𐤌𐤟𐤋𐤟𐤉𐤔𐤌𐤍",
        "𐤀𐤇𐤓𐤍𐤟𐤅𐤋𐤄𐤟𐤅𐤉𐤄𐤅𐤀𐤟𐤌",
        "𐤋𐤊𐤟𐤏𐤋𐤟𐤉𐤔𐤟𐤓𐤀𐤋",
    ].joined(separator: "\n")

    // The two legends of the half shekel: "Half shekel" / "Jerusalem the holy".
    static let halfShekel = "𐤇𐤑𐤉𐤟𐤄𐤔𐤒𐤋\n𐤉𐤓𐤅𐤔𐤋𐤌𐤟𐤄𐤒𐤃𐤔𐤄"
}

// MARK: - Zoomable full-screen image

private struct IdentifiedString: Identifiable { let id: String }

private struct ZoomableImageView: View {
    let asset: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(asset)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in scale = max(1, lastScale * value.magnification) }
                        .onEnded { _ in lastScale = scale }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            guard scale > 1 else { return }
                            offset = CGSize(width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height)
                        }
                        .onEnded { _ in lastOffset = offset }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.smooth) {
                        if scale > 1 { scale = 1; offset = .zero; lastOffset = .zero; lastScale = 1 }
                        else { scale = 2.5; lastScale = 2.5 }
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                    .padding()
                }
                Spacer()
                Text("Pinch or double-tap to zoom")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, Spacing.xl)
            }
        }
    }
}

// MARK: - Helpers

private func assetExists(_ name: String) -> Bool {
    #if canImport(UIKit)
    return UIImage(named: name) != nil
    #else
    return false
    #endif
}

struct WikipediaMark: View {
    var body: some View {
        Text("W")
            .font(.system(size: 14, weight: .semibold, design: .serif))
            .frame(width: 26, height: 26)
            .background(Circle().fill(Color(.tertiarySystemFill)))
            .foregroundStyle(.primary)
    }
}

#Preview {
    NavigationStack { AboutPaleoHebrewView() }
}
