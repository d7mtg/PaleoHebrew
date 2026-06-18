import AppIntents
import SwiftUI

/// Exposes the converter to Siri, Spotlight, the Shortcuts app, and the Action
/// Button. The conversion engine is pure, so the intent runs without launching
/// the UI.
struct ConvertToPaleoIntent: AppIntent {
    static var title: LocalizedStringResource = "Convert to Paleo-Hebrew"
    static var description = IntentDescription("Convert modern Hebrew text into the ancient Paleo-Hebrew script.")

    @Parameter(title: "Text", inputOptions: String.IntentInputOptions(capitalizationType: .none))
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Convert \(\.$text) to Paleo-Hebrew")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let result = ConversionEngine.convert(
            text, modernToPaleo: true,
            options: .init(stripNiqqud: true, spacesAsDots: false, autoFinal: false, cleanInscription: false)
        )
        return .result(value: result, dialog: IntentDialog(stringLiteral: result))
    }
}

/// The reverse direction: Paleo back to modern Hebrew.
struct ConvertToModernIntent: AppIntent {
    static var title: LocalizedStringResource = "Convert Paleo-Hebrew to Modern"
    static var description = IntentDescription("Convert Paleo-Hebrew text back into modern Hebrew letters.")

    @Parameter(title: "Paleo-Hebrew text")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Convert \(\.$text) to modern Hebrew")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let result = ConversionEngine.convert(
            text, modernToPaleo: false,
            options: .init(stripNiqqud: true, spacesAsDots: false, autoFinal: true, cleanInscription: true)
        )
        return .result(value: result, dialog: IntentDialog(stringLiteral: result))
    }
}

/// Opens the quiz. Drives the same app-level selection the menu commands use.
struct StartQuizIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a Paleo-Hebrew Quiz"
    static var description = IntentDescription("Open Paleo Pro and start a new quiz.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppNavigation.shared.startQuiz()
        return .result()
    }
}

/// System-suggested phrases. These appear in Spotlight and the Shortcuts app
/// automatically once the app is installed.
struct PaleoShortcuts: AppShortcutsProvider {
    /// Default tile color when a shortcut is added to the Home Screen / shown in
    /// the Shortcuts app — match the app's teal instead of the default.
    static var shortcutTileColor: ShortcutTileColor { .teal }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ConvertToPaleoIntent(),
            phrases: [
                "Convert to Paleo-Hebrew with \(.applicationName)",
                "Paleo-Hebrew with \(.applicationName)",
            ],
            shortTitle: "Convert to Paleo",
            systemImageName: "arrow.left.arrow.right"
        )
        AppShortcut(
            intent: ConvertToModernIntent(),
            phrases: [
                "Convert Paleo to Hebrew with \(.applicationName)",
            ],
            shortTitle: "Convert to Modern",
            systemImageName: "arrow.left.arrow.right"
        )
        AppShortcut(
            intent: StartQuizIntent(),
            phrases: [
                "Start a quiz in \(.applicationName)",
                "Quiz me in \(.applicationName)",
            ],
            shortTitle: "Start Quiz",
            systemImageName: "gamecontroller"
        )
    }
}
