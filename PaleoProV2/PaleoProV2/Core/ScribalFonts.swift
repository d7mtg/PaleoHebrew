import SwiftUI
import CoreText

/// The bundled Culmus "Ancient Semitic Scripts" fonts (by the late Yoram Gnat,
/// Culmus Project, GPL v2 + font-embedding exception). Unlike the older
/// BibleWorks-keyed fonts, these map their glyphs to the **Hebrew Unicode
/// range (U+05D0–U+05EA)**, so we render them by feeding the modern Hebrew
/// letter directly — no ASCII keymap, and no per-font surprises.
///
/// They form a complete genealogy of the alphabet, from pictographic
/// Proto-Canaanite through Phoenician, Paleo-Hebrew, Aramaic, and the square
/// script, all the way to the modern letterform.
struct ScribalFont: Identifiable, Hashable {
    let id: String              // resource basename (no extension)
    let postScriptName: String
    let displayName: String
    let era: String
    let sortOrder: Int          // chronological
    /// Offered in the global "letterform" picker (the distinctly ancient,
    /// pre-modern hands). Square and modernized scripts are excluded there.
    let isAncientHand: Bool
    var inDefaultTimeline = false
    var note: String = ""
}

enum ScribalFonts {
    static let all: [ScribalFont] = [
        .init(id: "PROTOCN", postScriptName: "Proto-Canaanite", displayName: "Proto-Canaanite",
              era: "c. 1700 BCE", sortOrder: 10, isAncientHand: true, inDefaultTimeline: true,
              note: "The pictographic root of the alphabet, scratched into rock by Semitic workers at Serabit el-Khadim in Sinai. Each sign began as a little picture."),
        .init(id: "AHIRAM", postScriptName: "Phoenician-Ahiram", displayName: "Phoenician",
              era: "c. 1000 BCE", sortOrder: 20, isAncientHand: true, inDefaultTimeline: true,
              note: "From the sarcophagus of King Ahiram of Byblos. Phoenician and Paleo-Hebrew were nearly the same script; this is the form that traveled west and became Greek and Latin."),
        .init(id: "GEZER", postScriptName: "Hebrew-Paleo-Gezer", displayName: "Paleo-Hebrew · Gezer",
              era: "10th c. BCE", sortOrder: 30, isAncientHand: true),
        .init(id: "MESHA", postScriptName: "Hebrew-Paleo-Mesha", displayName: "Paleo-Hebrew · Mesha Stele",
              era: "9th c. BCE", sortOrder: 40, isAncientHand: true),
        .init(id: "BR_RKB", postScriptName: "Aramaic-Early-Br-Rkb", displayName: "Early Aramaic · Bar-Rakib",
              era: "8th c. BCE", sortOrder: 50, isAncientHand: true,
              note: "Aramaic, written in a script still close to Paleo-Hebrew but beginning to drift."),
        .init(id: "AVIIBCE", postScriptName: "Aramaic-VIIBCE", displayName: "Aramaic · Gözne",
              era: "7th c. BCE", sortOrder: 55, isAncientHand: true),
        .init(id: "SILOAM", postScriptName: "Hebrew-Paleo-Siloam", displayName: "Paleo-Hebrew · Siloam",
              era: "703 BCE", sortOrder: 60, isAncientHand: true, inDefaultTimeline: true,
              note: "From the Siloam Inscription in Hezekiah's Tunnel, Jerusalem. Classic First-Temple Paleo-Hebrew."),
        .init(id: "LACHISH", postScriptName: "Hebrew-Paleo-Lachish", displayName: "Paleo-Hebrew · Lachish",
              era: "587 BCE", sortOrder: 70, isAncientHand: true,
              note: "The Lachish Letters, written in ink on pottery in the last days before Jerusalem fell to Babylon."),
        .init(id: "YEB", postScriptName: "Aramaic-Imperial-Yeb", displayName: "Imperial Aramaic · Elephantine",
              era: "407 BCE", sortOrder: 80, isAncientHand: true, inDefaultTimeline: true,
              note: "Persian-era Aramaic from the Jewish community at Elephantine in Egypt. Here the letters are flattening and squaring off, on the way to the script we use today."),
        .init(id: "QUMRAN", postScriptName: "Hebrew-Paleo-Qumran", displayName: "Paleo-Hebrew · Qumran",
              era: "2nd c. BCE", sortOrder: 90, isAncientHand: true,
              note: "A deliberate revival of the old Paleo script by some scribes of the Dead Sea Scrolls, centuries after it had fallen from daily use."),
        .init(id: "ISAIAH", postScriptName: "Hebrew-Square-Isaiah", displayName: "Square Hebrew · Isaiah Scroll",
              era: "2nd c. BCE", sortOrder: 100, isAncientHand: false, inDefaultTimeline: true,
              note: "The Great Isaiah Scroll from Qumran, in the Aramaic-derived square script. The letters have nearly reached their modern form."),
        .init(id: "HABAKKUK", postScriptName: "Hebrew-Square-Habakkuk", displayName: "Square Hebrew · Habakkuk",
              era: "1st c. BCE", sortOrder: 110, isAncientHand: false),
        .init(id: "BETSHEAR", postScriptName: "Hebrew-Square-Bet-Shearim", displayName: "Square Hebrew · Bet She'arim",
              era: "3rd c. CE", sortOrder: 120, isAncientHand: false),
        .init(id: "BENKOSBA", postScriptName: "Hebrew-Square-BenKosba", displayName: "Square Hebrew · Bar Kokhba",
              era: "132 CE", sortOrder: 130, isAncientHand: false,
              note: "From the letters of Shimon bar Kokhba, leader of the revolt against Rome."),
        .init(id: "Hebrew-Samaritan", postScriptName: "Hebrew-Samaritan", displayName: "Samaritan",
              era: "still in use", sortOrder: 140, isAncientHand: true,
              note: "The Samaritan community never switched to the square script. Their writing is a living descendant of Paleo-Hebrew, still in use today."),
        .init(id: "MakabiYG", postScriptName: "MakabiYG", displayName: "Makabi (modern revival)",
              era: "modern", sortOrder: 150, isAncientHand: false,
              note: "A clean, legible modern typeface based on the Isaiah Scroll hand."),
    ]

    /// Fonts offered in the global letterform picker (ancient hands only).
    static let globalEligible: [ScribalFont] =
        all.filter(\.isAncientHand).sorted { $0.sortOrder < $1.sortOrder }

    /// Curated milestones (oldest → most modern) for the default timeline.
    static let timelineDefault: [ScribalFont] =
        all.filter(\.inDefaultTimeline).sorted { $0.sortOrder < $1.sortOrder }

    /// Every script, oldest → newest.
    static let timelineAll: [ScribalFont] =
        all.sorted { $0.sortOrder < $1.sortOrder }

    private static let byID: [String: ScribalFont] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func font(id: String) -> ScribalFont? { byID[id] }

    // MARK: Registration

    private static var registered = false
    static func registerAll() {
        guard !registered else { return }
        registered = true
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        for url in Bundle.main.urls(forResourcesWithExtension: "TTF", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Convert any Paleo-Unicode (or already-modern) string into the modern
    /// Hebrew letters these fonts are keyed on.
    static func modernText(for text: String) -> String {
        text.map { Alphabet.paleoToModern[String($0)] ?? String($0) }.joined()
    }
}

/// The user's chosen Paleo letterform. Empty = default Unicode Paleo font.
/// Stored in the App Group so the keyboard extension sees the same choice.
enum PaleoFontPreference {
    static let key = "paleoFontID"
    static let store = UserDefaults(suiteName: Shared.appGroup) ?? .standard
}

/// Renders Paleo-Hebrew text. If the user has chosen a scribal font (and the
/// text contains Paleo glyphs), it renders the modern-Hebrew equivalent in that
/// font (these fonts are keyed on the Hebrew Unicode range). Otherwise it draws
/// the system Unicode Paleo glyphs. Non-Paleo text is always drawn as-is.
struct PaleoGlyph: View {
    let text: String
    var size: CGFloat
    var weight: Font.Weight = .regular

    @AppStorage(PaleoFontPreference.key, store: PaleoFontPreference.store) private var fontID = ""

    private var isPaleo: Bool {
        text.unicodeScalars.contains(where: Alphabet.isPaleoScalar)
    }

    private var scribal: ScribalFont? {
        guard !fontID.isEmpty, isPaleo else { return nil }
        return ScribalFonts.font(id: fontID)
    }

    var body: some View {
        if let scribal {
            Text(ScribalFonts.modernText(for: text))
                .font(.custom(scribal.postScriptName, size: size))
        } else {
            Text(text).font(.system(size: size, weight: weight))
        }
    }
}
