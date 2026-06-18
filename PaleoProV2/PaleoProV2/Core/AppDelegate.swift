import UIKit

/// Bridges the bits of app lifecycle SwiftUI doesn't cover: Spotlight indexing
/// and Home-Screen quick actions. All routing goes through `AppNavigation` so
/// there's one destination for every entry point.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        SpotlightIndex.indexLetters()
        application.shortcutItems = AppDelegate.quickActions
        return true
    }

    /// Home-Screen long-press shortcuts (set dynamically so no Info.plist array
    /// is needed under generated Info.plist).
    static let quickActions: [UIApplicationShortcutItem] = [
        UIApplicationShortcutItem(type: "convert", localizedTitle: "Convert",
                                  localizedSubtitle: nil,
                                  icon: UIApplicationShortcutIcon(systemImageName: "arrow.left.arrow.right")),
        UIApplicationShortcutItem(type: "quiz", localizedTitle: "Start a Quiz",
                                  localizedSubtitle: nil,
                                  icon: UIApplicationShortcutIcon(systemImageName: "gamecontroller")),
        UIApplicationShortcutItem(type: "today", localizedTitle: "Today's Letter",
                                  localizedSubtitle: nil,
                                  icon: UIApplicationShortcutIcon(systemImageName: "calendar")),
    ]

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

/// Handles quick actions for both cold launch and while running.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let item = connectionOptions.shortcutItem { handle(item) }
    }

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handle(shortcutItem))
    }

    @discardableResult
    private func handle(_ item: UIApplicationShortcutItem) -> Bool {
        Task { @MainActor in
            switch item.type {
            case "convert": AppNavigation.shared.showConvert()
            case "quiz":    AppNavigation.shared.startQuiz()
            case "today":   AppNavigation.shared.open(letterID: Alphabet.letterOfTheDay.id)
            default: break
            }
        }
        return true
    }
}
