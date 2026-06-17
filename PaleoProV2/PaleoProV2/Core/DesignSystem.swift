import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Spacing (4 / 8-pt grid)

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16   // default screen edge inset
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 40
}

// MARK: - Corner radii (always .continuous; obey outer = inner + padding)

enum Radius {
    static let chip: CGFloat = 10
    static let button: CGFloat = 14
    static let card: CGFloat = 20
    static let sheet: CGFloat = 28

    /// Concentric outer radius for a surface wrapping content with `inset`.
    static func concentric(inner: CGFloat, padding: CGFloat) -> CGFloat {
        inner + padding
    }
}

extension RoundedRectangle {
    /// Continuous (superellipse) rounded rect — the iOS squircle.
    static func continuous(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

// MARK: - Motion tokens

enum Motion {
    /// Press / release of a tappable. ~150ms, interruptible.
    static let press = Animation.spring(response: 0.15, dampingFraction: 0.7)
    /// Frequent UI changes — toggles, selection, segmented controls.
    static let snappy = Animation.snappy(duration: 0.28)
    /// Content / view transitions the eye tracks. Under 300ms, no overshoot.
    static let smooth = Animation.smooth(duration: 0.3)
    /// Slightly longer reveal for larger surfaces.
    static let content = Animation.smooth(duration: 0.4)
    /// Delight only — success, onboarding, empty-state flourishes.
    static let bouncy = Animation.spring(duration: 0.5, bounce: 0.28)
    /// A restrained pop for emphasis.
    static let emphasis = Animation.spring(response: 0.4, dampingFraction: 0.78)
}

/// "Materialize" transition: opacity + blur + a small vertical drift.
/// Enters from +8pt, leaves upward to −12pt (exit subtler & faster).
struct Materialize: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 4)
            .offset(y: phase.isIdentity ? 0 : (phase == .willAppear ? 8 : -12))
    }
}

extension AnyTransition {
    static var materialize: AnyTransition { .init(Materialize()) }
}

// MARK: - Tactile button style

/// Scales to 0.96 on press with a snappy, interruptible spring. The single
/// most reliable way to make a control feel physical.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
    static func pressable(scale: CGFloat) -> PressableStyle { PressableStyle(scale: scale) }
}

// MARK: - Glass

extension Color {
    #if canImport(UIKit)
    /// Foreground for text/icons placed on top of the brand teal — white in
    /// light mode, **black in dark mode** where the lighter teal pushes the
    /// white contrast too low (AA fail).
    static let onAccent = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .black : .white
    })
    /// Card surface — white on light, a *lifted* dark gray on dark so cards
    /// separate from the OLED-black grouped background (#1C1C1E reads as a void).
    static let cardFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.16, blue: 0.175, alpha: 1)
            : .secondarySystemGroupedBackground
    })
    static let cardStroke = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.clear
    })
    /// Cross-platform equivalent of `.systemGroupedBackground`.
    static let appBackground = Color(uiColor: .systemGroupedBackground)
    /// Cross-platform equivalent of `.systemGray5` (track / quiet fills).
    static let trackFill = Color(uiColor: .systemGray5)
    #else
    static let onAccent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? .black : .white
    })
    static let cardFill = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            ? NSColor(red: 0.16, green: 0.16, blue: 0.175, alpha: 1)
            : NSColor.controlBackgroundColor
    })
    static let cardStroke = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            ? NSColor.white.withAlphaComponent(0.08)
            : .clear
    })
    static let appBackground = Color(nsColor: .windowBackgroundColor)
    static let trackFill = Color(nsColor: .quaternaryLabelColor)
    #endif
}

extension View {
    /// Continuous rounded card with an adaptive fill plus a hairline that gives
    /// it real definition on dark backgrounds.
    func cardSurface(_ radius: CGFloat = Radius.card, fill: Color = .cardFill) -> some View {
        background(fill, in: .rect(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.cardStroke, lineWidth: 0.75)
            )
    }

    /// A Liquid-Glass surface with a continuous-rounded shape. Use for
    /// floating / control surfaces only — never for bulk content.
    @ViewBuilder
    func glassCard(_ radius: CGFloat = Radius.card) -> some View {
        self.glassEffect(.regular, in: .rect(cornerRadius: radius))
    }

    /// Expands the hit target to at least 44×44 while keeping the visual size.
    func tappableTarget() -> some View {
        frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
    }
}
