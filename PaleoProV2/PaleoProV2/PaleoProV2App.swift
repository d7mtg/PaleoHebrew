import SwiftUI
import SwiftData

@main
struct PaleoProV2App: App {
    /// Selection lives at the App level so hardware-keyboard / menu commands
    /// can drive it (⌘1–⌘4 on iPad, etc.).
    @State private var selection: AppTab = .initialFromEnvironment
    /// Bumped by File → New Quiz; PlayView watches it and resets the engine.
    @State private var newQuizTrigger: Int = 0

    init() {
        // Register the bundled scribal fonts so Font.custom resolves them.
        ScribalFonts.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView(selection: $selection)
                .environment(\.newQuizTrigger, newQuizTrigger)
        }
        .modelContainer(Persistence.makeContainer())
        .commands {
            // File → New Quiz (⌘N) — also drives the iPad hardware keyboard.
            CommandGroup(replacing: .newItem) {
                Button("New Quiz") {
                    selection = .play
                    newQuizTrigger &+= 1
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            // View — ⌘1 … ⌘4 jump between sections.
            CommandGroup(before: .sidebar) {
                Section {
                    ForEach(Array(AppTab.allCases.enumerated()), id: \.element) { index, tab in
                        Button(tab.title) { selection = tab }
                            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")),
                                              modifiers: .command)
                    }
                }
            }
            // Preferences shortcut routes to the Settings tab.
            CommandGroup(after: .appInfo) {
                Button("Settings…") { selection = .settings }
                    .keyboardShortcut(",", modifiers: .command)
            }
            // Help → brand site.
            CommandGroup(replacing: .help) {
                Link("Paleo Pro Help", destination: URL(string: "https://aleph.d7mtg.com")!)
            }
        }
    }
}

// MARK: - New-quiz trigger plumbing

private struct NewQuizTriggerKey: EnvironmentKey { static let defaultValue: Int = 0 }

extension EnvironmentValues {
    var newQuizTrigger: Int {
        get { self[NewQuizTriggerKey.self] }
        set { self[NewQuizTriggerKey.self] = newValue }
    }
}
