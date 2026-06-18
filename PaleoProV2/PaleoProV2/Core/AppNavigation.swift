import SwiftUI

/// One coordinator every external entry point drives: App Intents, Home-Screen
/// quick actions, Spotlight deep links, Handoff, and the in-app menu commands.
/// Keeping a single source of truth means none of those need their own ad-hoc
/// routing.
@MainActor
@Observable
final class AppNavigation {
    static let shared = AppNavigation()
    private init() { selectedTab = .initialFromEnvironment }

    /// The visible tab / sidebar selection.
    var selectedTab: AppTab
    /// Bumped to request a fresh quiz; PlayView watches it.
    var quizToken = 0
    /// Bumped (from the Settings debug menu) to re-present the What's New sheet.
    var whatsNewToken = 0
    /// Set to open a specific letter's sheet in Learn (e.g. from Spotlight).
    var letterToOpen: PaleoLetter?

    /// Handoff: a conversion carried over from another device.
    var pendingConvertText: String?
    var pendingConvertModernToPaleo = true
    var convertToken = 0

    static let convertActivityType = "com.d7mtg.PaleoHebrew.convert"

    func showConvert() { selectedTab = .convert }
    func showSettings() { selectedTab = .settings }

    func continueConvert(text: String, modernToPaleo: Bool) {
        pendingConvertText = text
        pendingConvertModernToPaleo = modernToPaleo
        selectedTab = .convert
        convertToken &+= 1
    }

    func startQuiz() {
        selectedTab = .play
        quizToken &+= 1
    }

    func open(letterID: String) {
        guard let letter = Alphabet.letters.first(where: { $0.id == letterID }) else { return }
        selectedTab = .learn
        letterToOpen = letter
    }
}
