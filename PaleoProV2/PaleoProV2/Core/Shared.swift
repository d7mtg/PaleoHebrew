import Foundation

/// Identifiers shared between the app and its keyboard extension.
enum Shared {
    /// App Group used for cross-process state. Must match the value declared
    /// in both targets' entitlements (PaleoProV2.entitlements and
    /// PaleoProV2Keyboard.entitlements). Matches V1's group so existing
    /// installs upgrade in place.
    static let appGroup = "group.com.d7mtg.PaleoHebrew"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    enum Key {
        /// Written by the keyboard extension the first time it appears, so the
        /// app can confirm setup succeeded.
        static let keyboardHasLaunched = "keyboardHasLaunched"
    }
}
