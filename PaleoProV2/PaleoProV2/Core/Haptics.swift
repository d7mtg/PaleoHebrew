import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Lightweight, cross-platform haptics. iOS/iPadOS uses UIFeedbackGenerator;
/// macOS routes to NSHapticFeedbackManager (Force Touch trackpads only — silent
/// elsewhere). Same call sites everywhere.
@MainActor
enum Haptics {
    /// A unified strength for impact-style haptics. iOS maps each case to
    /// `UIImpactFeedbackGenerator.FeedbackStyle`; macOS ignores it.
    enum Impact { case light, medium, heavy, soft, rigid }

    static func impact(_ style: Impact = .medium, intensity: CGFloat = 1) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style.uiKit).impactOccurred(intensity: intensity)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }

    static func tap() { impact(.light, intensity: 0.7) }

    static func select() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }

    static func prepare() {}
}

#if canImport(UIKit)
private extension Haptics.Impact {
    var uiKit: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        case .soft: .soft
        case .rigid: .rigid
        }
    }
}
#endif
