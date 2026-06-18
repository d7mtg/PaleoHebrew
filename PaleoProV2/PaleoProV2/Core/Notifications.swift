import Foundation
import UserNotifications

/// Local-notification support, done the Apple-recommended way: permission is
/// requested in context (after the What's New screen, when the value is clear),
/// never cold at launch.
///
/// NOTE ON REACHING PAST USERS: iOS cannot push to users who never granted
/// permission, because no device tokens exist for them. The App Store update is
/// the channel that tells the existing install base a new version shipped. What
/// the app does here: register provisionally so notifications deliver quietly
/// with no prompt, then fire a one-time "big update" announcement a day after a
/// returning user opens the update. A true server broadcast would need APNs plus
/// a backend and the Push capability; the app ships with local notifications only.
@MainActor
enum Notifications {
    private static let center = UNUserNotificationCenter.current()

    private enum Key {
        static let scheduledWhatsNew2 = "notif.scheduledWhatsNew2_0"
    }

    /// Provisional authorization: notifications start delivering **quietly**
    /// (to Notification Center, no banner/sound, no up-front "Allow?" prompt).
    /// iOS later asks the user whether to keep them or turn them off. This is
    /// the lowest-friction, highest-reach path Apple allows — the right call
    /// for a one-time announcement to returning users. Call it on launch.
    static func registerProvisional() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
    }

    /// Explicit prompt (the loud "Allow?" dialog). Kept for callers that want a
    /// deliberate opt-in; the app uses provisional by default.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Current authorization status, so callers can avoid re-prompting.
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// One-time "big update" announcement, fired a day after a returning user
    /// opens the updated app. Version-agnostic so it reads right whether they
    /// came from 1.0 or 2.0. Guarded so it only schedules once per install.
    static func scheduleUpdateAnnouncementIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Key.scheduledWhatsNew2) else { return }
        UserDefaults.standard.set(true, forKey: Key.scheduledWhatsNew2)

        let content = UNMutableNotificationContent()
        content.title = "Paleo Pro just got a big update"
        content.body = "A new design, a redesigned keyboard, Home Screen widgets, and more. Tap to take a look."
        content.sound = .default

        // ~24 hours later, so it lands as a gentle re-engagement rather than
        // firing while the user is already in the app.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
        center.add(UNNotificationRequest(identifier: "paleo.updateAnnouncement", content: content, trigger: trigger))
    }
}
