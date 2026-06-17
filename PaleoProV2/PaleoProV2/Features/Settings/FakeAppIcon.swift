import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The Settings header icon — visually identical to the home-screen app icon
/// (teal gradient + the Aleph mark vector). Tap it for a burst of Paleo
/// letters; hold it for a continuous, accelerating spray.
struct FakeAppIcon: View {
    var body: some View {
        ZStack {
            art
            #if canImport(UIKit)
                .overlay(
                    IconSprayAnchor(
                        onTap: { center in LetterSpray.fire(from: center, with: .impact(.medium)) },
                        onHoldTick: { center in LetterSpray.fire(from: center, with: .randomImpact) }
                    )
                )
            #endif
        }
        // No context menu — the hold gesture is reserved for the spray.
        .accessibilityLabel("Paleo Pro app icon")
        .accessibilityHint("Tap for a burst of letters; hold for a continuous spray")
    }

    private var art: some View {
        IconArt()
    }
}

/// Mirrors the home-screen Icon Composer icon, adaptive for dark mode:
///  • Light: teal gradient bg, white Aleph mark, glass material overlay.
///  • Dark: near-black gradient bg (lighter at top), teal Aleph mark, glass overlay.
private struct IconArt: View {
    @Environment(\.colorScheme) private var scheme

    private var gradient: LinearGradient {
        if scheme == .dark {
            // Black at the bottom, slightly lighter at the top — gives the icon
            // depth in dark mode so it doesn't merge with the background.
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.16, green: 0.17, blue: 0.18),
                    Color(.sRGB, red: 0.05, green: 0.05, blue: 0.06),
                ],
                startPoint: .top, endPoint: .bottom)
        } else {
            // Brand teal from icon.json (P3 → sRGB).
            LinearGradient(
                colors: [
                    Color(.displayP3, red: 0.317, green: 0.859, blue: 0.872),
                    Color(.sRGB, red: 0.000, green: 0.621, blue: 0.745),
                ],
                startPoint: .top, endPoint: .bottom)
        }
    }

    private var markColor: Color {
        // Inverts between modes: white on teal (light) ↔ teal on black (dark).
        scheme == .dark
            ? Color(.sRGB, red: 0.10, green: 0.78, blue: 0.83)
            : .white
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(gradient)
            .overlay {
                Image("AppIconMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(markColor)
                    .padding(18)
            }
            .overlay {
                // Subtle hairline so dark-mode icon has a defined edge.
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(scheme == .dark ? 0.08 : 0), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.15), radius: 8, y: 4)
    }
}

#if canImport(UIKit)
// MARK: - Letter spray (UIKit overlay so the burst escapes SwiftUI clipping)

enum LetterSpray {
    enum Tactile { case impact(UIImpactFeedbackGenerator.FeedbackStyle), randomImpact, none }

    /// Glyphs the burst draws from — Paleo letters (the app's own alphabet)
    /// plus a few related Hebrew points for variety.
    private static let glyphs: [String] = Alphabet.letters.map(\.paleo)
        + Alphabet.letters.map(\.modern)
    /// Variations on the brand teal — light to dark, slightly shifted in hue,
    /// for a coherent confetti palette instead of a rainbow.
    private static let colors: [UIColor] = [
        UIColor(red: 0.20, green: 0.86, blue: 0.92, alpha: 1), // bright cyan-teal
        UIColor(red: 0.00, green: 0.74, blue: 0.83, alpha: 1), // brand teal
        UIColor(red: 0.00, green: 0.62, blue: 0.74, alpha: 1), // deep teal
        UIColor(red: 0.00, green: 0.49, blue: 0.62, alpha: 1), // darker teal
        UIColor(red: 0.32, green: 0.78, blue: 0.78, alpha: 1), // muted teal
        UIColor(red: 0.10, green: 0.55, blue: 0.55, alpha: 1), // forest teal
        UIColor(red: 0.50, green: 0.92, blue: 0.94, alpha: 1), // pale teal
    ]

    static func fire(from screenPoint: CGPoint, with tactile: Tactile = .impact(.medium)) {
        switch tactile {
        case .impact(let style):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        case .randomImpact:
            let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .rigid, .soft]
            UIImpactFeedbackGenerator(style: styles.randomElement()!)
                .impactOccurred(intensity: CGFloat.random(in: 0.4...1.0))
        case .none: break
        }

        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first?.windows.first else { return }

        let count = Int.random(in: 14...20)
        for _ in 0..<count {
            let label = UILabel()
            label.text = glyphs.randomElement()
            label.font = .systemFont(ofSize: CGFloat.random(in: 22...38), weight: .bold)
            label.textColor = colors.randomElement()
            label.sizeToFit()
            label.center = screenPoint
            window.addSubview(label)

            let angle = CGFloat.random(in: 0 ... .pi * 2)
            let distance = CGFloat.random(in: 80...200)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance - 80 // bias upward
            let rotation = CGFloat.random(in: -3...3)

            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
                label.center = CGPoint(x: screenPoint.x + dx, y: screenPoint.y + dy)
                label.transform = CGAffineTransform(rotationAngle: rotation)
            }
            UIView.animate(withDuration: 0.5, delay: 0.4, options: .curveEaseIn) {
                label.center.y += 120
                label.alpha = 0
                label.transform = label.transform.scaledBy(x: 0.3, y: 0.3)
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - Tap / long-press anchor that reports screen-space coords

private struct IconSprayAnchor: UIViewRepresentable {
    let onTap: (CGPoint) -> Void
    let onHoldTick: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.held(_:)))
        hold.minimumPressDuration = 0.25
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(hold)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap, onHoldTick: onHoldTick) }

    final class Coordinator: NSObject {
        let onTap: (CGPoint) -> Void
        let onHoldTick: (CGPoint) -> Void
        private var timer: Timer?
        private var interval: TimeInterval = 0.15

        init(onTap: @escaping (CGPoint) -> Void, onHoldTick: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
            self.onHoldTick = onHoldTick
        }

        private func screenCenter(of view: UIView) -> CGPoint {
            guard let window = view.window else { return .zero }
            return view.convert(CGPoint(x: view.bounds.midX, y: view.bounds.midY), to: window)
        }

        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            onTap(screenCenter(of: view))
        }

        @objc func held(_ gesture: UILongPressGestureRecognizer) {
            guard let view = gesture.view else { return }
            switch gesture.state {
            case .began:
                interval = 0.15
                onHoldTick(screenCenter(of: view))
                startTimer(view: view)
            case .ended, .cancelled, .failed:
                stopTimer()
            default: break
            }
        }

        private func startTimer(view: UIView) {
            stopTimer()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self, weak view] _ in
                guard let self, let view else { return }
                self.onHoldTick(self.screenCenter(of: view))
                self.interval = max(0.04, self.interval * 0.85) // accelerate the longer you hold
                self.startTimer(view: view)
            }
        }

        private func stopTimer() { timer?.invalidate(); timer = nil }
    }
}
#endif // canImport(UIKit)

#Preview {
    FakeAppIcon()
        .frame(width: 92, height: 92)
        .padding(60)
}
