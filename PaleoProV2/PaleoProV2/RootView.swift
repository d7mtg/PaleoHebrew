import SwiftUI

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

    var symbol: String {
        switch self {
        case .learn: "book.closed"
        case .play: "gamecontroller"
        case .convert: "arrow.left.arrow.right"
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
    @Binding var selection: AppTab

    init(selection: Binding<AppTab>) {
        self._selection = selection
    }

    private var sidebarTabs: [AppTab] { AppTab.allCases }

    // Shown on every launch for now. Before release, change the initial value
    // to gate on a stored version flag so it only appears once per update:
    //   @AppStorage("whatsNewSeenVersion") private var seenVersion = ""
    //   ... show when seenVersion != currentVersion, then set it on Continue.
    @State private var showWhatsNew = ProcessInfo.processInfo.environment["SKIP_WHATSNEW"] == nil

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                tabbed
            } else {
                sidebar
            }
        }
        .fullScreenCover(isPresented: $showWhatsNew) {
            WhatsNewView { showWhatsNew = false }
        }
    }

    // MARK: Compact (iPhone)

    private var tabbed: some View {
        TabView(selection: $selection) {
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
                get: { selection },
                set: { if let v = $0 { selection = v } }
            )) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.symbol)
                }
            }
            .listStyle(.sidebar) // source-list vibrancy on Mac, native on iPad
            .navigationTitle("Paleo Pro")
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            destination(selection)
                .id(selection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func destination(_ tab: AppTab) -> some View {
        switch tab {
        case .learn: LearnView()
        case .play: PlayView()
        case .convert: ConvertView()
        case .settings: SettingsView()
        }
    }

}

/// Helper used by the App to honor `PREVIEW_TAB` env override.
extension AppTab {
    static var initialFromEnvironment: AppTab {
        switch ProcessInfo.processInfo.environment["PREVIEW_TAB"] {
        case "play": return .play
        case "convert": return .convert
        case "settings": return .settings
        default: return .learn
        }
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .learn
    RootView(selection: $tab)
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
