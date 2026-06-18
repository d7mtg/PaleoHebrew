import SwiftUI
import CoreSpotlight

enum AppTab: Hashable, CaseIterable, Identifiable {
    case learn, play, convert, settings
    var id: Self { self }

    var title: String {
        switch self {
            
            
            
        case .learn: "Learn"
        case .play: "Play"
        case .convert: "Convert"
        case .settings: "Settings"
        }
    }

    // Outline symbols; SwiftUI's tab bar swaps each to its `.fill` variant when
    // the tab is selected. (All of these have a filled counterpart, unlike the
    // old arrow.left.arrow.right, which had none and so never filled.)
    var symbol: String {
        switch self {
        case .learn: "book.closed"
        case .play: "play.square.stack"
        case .convert: "arrow.left.arrow.right.square"
        case .settings: "gearshape"
        }
    }
} 

/// Adapts to the device class:
/// • compact horizontal (iPhone, narrow window) → `TabView` with bottom tabs.
/// • regular horizontal (iPad, Mac Catalyst, native macOS) → `NavigationSplitView`
///   with a floating Liquid Glass sidebar.
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var nav: AppNavigation

    private var sidebarTabs: [AppTab] { AppTab.allCases }

    // "What's New" shows once per app version: the flag stores the last version
    // whose screen was dismissed, so a new MARKETING_VERSION brings it back.
    @AppStorage("whatsNewSeenVersion") private var whatsNewSeenVersion = ""
    @State private var showWhatsNew = RootView.shouldShowWhatsNew()

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static func shouldShowWhatsNew() -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SKIP_WHATSNEW"] != nil { return false }
        #endif
        return UserDefaults.standard.string(forKey: "whatsNewSeenVersion") != currentVersion
    }

    var body: some View {
        #if DEBUG
        // Debug-only: render a share card full-screen for screenshots.
        if let name = ProcessInfo.processInfo.environment["SHARE_CARD"],
           let l = Alphabet.letters.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return AnyView(
                LetterShareCard(letter: l)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                    .task {
                        for s in [ColorScheme.light, .dark] {
                            if let img = LetterShareCard.render(letter: l, scheme: s),
                               let data = img.pngData() {
                                let url = URL.documentsDirectory.appending(path: "card_\(s == .dark ? "dark" : "light").png")
                                try? data.write(to: url)
                            }
                        }
                    }
            )
        }
        #endif
        return AnyView(mainContent)
    }

    private var mainContent: some View {
        Group {
            if horizontalSizeClass == .compact {
                tabbed
            } else {
                sidebar
            }
        }
        // A dismissible sheet (rounded top, swipe to dismiss) like Apple's
        // recent What's New. Either Continue or a swipe marks it seen.
        .sheet(isPresented: $showWhatsNew, onDismiss: {
            whatsNewSeenVersion = RootView.currentVersion
        }) {
            WhatsNewView { showWhatsNew = false }
                .presentationDragIndicator(.hidden)
        }
        // Debug menu can re-present What's New without reinstalling.
        .onChange(of: nav.whatsNewToken) { _, _ in showWhatsNew = true }
        // Register provisionally on launch: notifications begin delivering
        // quietly with no prompt, so the one-time "2.0 is here" announcement
        // reaches every returning user the moment they open the update.
        .task {
            await Notifications.registerProvisional()
            Notifications.scheduleUpdateAnnouncementIfNeeded()
            // Honor a route requested by a widget tile or the Control Center
            // control (both write pendingRoute into the App Group).
            let store = UserDefaults(suiteName: "group.com.d7mtg.PaleoHebrew")
            if let route = store?.string(forKey: "pendingRoute") {
                store?.removeObject(forKey: "pendingRoute")
                switch route {
                case "learn":    nav.selectedTab = .learn
                case "play":     nav.selectedTab = .play
                case "convert":  nav.showConvert()
                case "settings": nav.showSettings()
                default: break
                }
            }
        }
        // Spotlight result tapped → open that letter.
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                nav.open(letterID: id)
            }
        }
        // Handoff: a conversion continued from another device.
        .onContinueUserActivity(AppNavigation.convertActivityType) { activity in
            nav.continueConvert(text: activity.userInfo?["text"] as? String ?? "",
                                modernToPaleo: activity.userInfo?["m2p"] as? Bool ?? true)
        }
    }

    // MARK: Compact (iPhone)

    private var tabbed: some View {
        TabView(selection: $nav.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.symbol, value: tab) {
                    destination(tab)
                }
            }
        }
#if !os(macOS)
        .tabBarMinimizeBehavior(.onScrollDown)
#endif
    }

    // MARK: Regular (iPad / Mac)

    private var sidebar: some View {
        NavigationSplitView {
            List(sidebarTabs, selection: Binding(
                get: { nav.selectedTab },
                set: { if let v = $0 { nav.selectedTab = v } }
            )) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.symbol)
                }
            }
            .listStyle(.sidebar) // source-list vibrancy on Mac, native on iPad
            .navigationTitle("Paleo Pro")
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            destination(nav.selectedTab)
                .id(nav.selectedTab)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func destination(_ tab: AppTab) -> some View {
        switch tab {
        case .learn: LearnView(letterToOpen: $nav.letterToOpen)
        case .play: PlayView(quizToken: nav.quizToken)
        case .convert: ConvertView()
        case .settings: SettingsView()
        }
    }

}

extension AppTab {
    /// Honors a `PREVIEW_TAB` env override in Debug builds (used to launch
    /// straight to a tab for screenshots); always `.learn` in Release.
    static var initialFromEnvironment: AppTab {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["PREVIEW_TAB"] {
        case "play": return .play
        case "convert": return .convert
        case "settings": return .settings
        default: return .learn
        }
        #else
        return .learn
        #endif
    }
}

#Preview {
    RootView(nav: AppNavigation.shared)
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
