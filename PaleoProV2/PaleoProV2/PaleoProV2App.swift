import SwiftUI
import SwiftData

@main
struct PaleoProV2App: App {
    /// Single navigation coordinator, shared with App Intents / quick actions /
    /// Spotlight / Handoff. Menu commands drive it too.
    @State private var nav = AppNavigation.shared
    #if !os(macOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    init() {
        // Register the bundled scribal fonts so Font.custom resolves them.
        ScribalFonts.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView(nav: nav)
                // Drive the whole hierarchy from the brand teal. The asset
                // AccentColor already tints buttons, but text selection, cursors
                // and other tint-driven controls fall back to system blue
                // without an explicit root tint.
                .tint(.accentColor)
        }
        .modelContainer(Persistence.makeContainer())
        .commands {
            // File → New Quiz (⌘N) — also drives the iPad hardware keyboard.
            CommandGroup(replacing: .newItem) {
                Button("New Quiz") { nav.startQuiz() }
                    .keyboardShortcut("n", modifiers: .command)
            }
            // View — ⌘1 … ⌘4 jump between sections.
            CommandGroup(before: .sidebar) {
                Section {
                    ForEach(Array(AppTab.allCases.enumerated()), id: \.element) { index, tab in
                        Button(tab.title) { nav.selectedTab = tab }
                            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")),
                                              modifiers: .command)
                    }
                }
            }
            // Preferences shortcut routes to the Settings tab.
            CommandGroup(after: .appInfo) {
                Button("Settings…") { nav.showSettings() }
                    .keyboardShortcut(",", modifiers: .command)
            }
            // Help → brand site.
            CommandGroup(replacing: .help) {
                Link("Paleo Pro Help", destination: URL(string: "https://aleph.d7mtg.com")!)
            }
        }
    }
}
