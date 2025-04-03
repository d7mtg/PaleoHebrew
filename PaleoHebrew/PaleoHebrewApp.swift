import SwiftUI

@main
struct PaleoProApp: App {
    // Pull the selected accent color from user defaults
    @AppStorage("selectedAccentColor") private var selectedAccentColor: String = "teal"

    init() {
        // Apply accent color at app launch
        updateAccentColor()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // For iOS 14 & 15:
                .accentColor(Color(uiColor: systemUIColor(for: selectedAccentColor)))
                // If targeting only iOS 15+, you can do:
                // .tint(Color(uiColor: systemUIColor(for: selectedAccentColor)))
                //
                // Watch for changes in the color & update UI
                .onChange(of: selectedAccentColor) { oldValue, newValue in
                    updateAccentColor()
                }
                // Alternative for iOS 17+ only (zero parameter version):
                // .onChange(of: selectedAccentColor) {
                //     updateAccentColor()
                // }
        }
    }


    /// Applies the selectedAccentColor to system UI elements.
    private func updateAccentColor() {
        let uiColor = systemUIColor(for: selectedAccentColor)
        // Nav bars
        UINavigationBar.appearance().tintColor = uiColor
        // Tab bars
        UITabBar.appearance().tintColor = uiColor
    }
}

/// Same helper from your SettingsView:
fileprivate func systemUIColor(for colorName: String) -> UIColor {
    switch colorName {
    case "blue": return .systemBlue
    case "neutral": return .label
    case "green": return .systemGreen
    case "orange": return .systemOrange
    case "pink": return .systemPink
    case "purple": return .systemPurple
    case "red": return .systemRed
    case "teal": return .systemTeal
    case "indigo": return .systemIndigo
    default: return .systemBlue
    }
}


