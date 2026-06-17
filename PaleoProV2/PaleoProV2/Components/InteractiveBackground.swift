import SwiftUI
#if os(iOS)
import CoreMotion
#endif

/// A faint, tiled field of Paleo glyphs that parallax-tilts with the device.
/// Frozen when Reduce Motion is on (and naturally static on the simulator,
/// where device motion is unavailable).
struct InteractiveBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = MotionProvider()
    @AppStorage(PaleoFontPreference.key, store: PaleoFontPreference.store) private var fontID = ""

    private var tint: Color { Color.accentColor.opacity(0.14) }

    /// The chosen letterform (nil = default Unicode Paleo).
    private var scribalFont: ScribalFont? {
        fontID.isEmpty ? nil : ScribalFonts.font(id: fontID)
    }

    /// Glyphs + font follow the chosen letterform: a scribal font draws the
    /// modern Hebrew letters; otherwise the system draws the Unicode Paleo.
    private var glyphs: [String] {
        Alphabet.letters.map { scribalFont == nil ? $0.paleo : $0.modern }
    }
    private var glyphFont: Font {
        if let f = scribalFont { return .custom(f.postScriptName, size: 54) }
        return .system(size: 54)
    }

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 86
            // Resolve each distinct glyph once, not once per tile per frame.
            let resolved = glyphs.map { glyph -> GraphicsContext.ResolvedText in
                var r = context.resolve(Text(glyph).font(glyphFont))
                r.shading = .color(tint)
                return r
            }
            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2
            var i = 0
            for r in 0...rows {
                for c in 0...cols {
                    let stagger = r.isMultiple(of: 2) ? spacing / 2 : 0
                    context.draw(
                        resolved[i % resolved.count],
                        at: CGPoint(x: CGFloat(c) * spacing - spacing + stagger,
                                    y: CGFloat(r) * spacing - spacing)
                    )
                    i += 1
                }
            }
        }
        // Scaled up so the more-extreme parallax offset never exposes an edge.
        .scaleEffect(1.32)
        .offset(x: reduceMotion ? 0 : motion.dx, y: reduceMotion ? 0 : motion.dy)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear { if !reduceMotion { motion.start() } }
        .onDisappear { motion.stop() }
    }
}

@MainActor
@Observable
final class MotionProvider {
    var dx: CGFloat = 0
    var dy: CGFloat = 0

    #if os(iOS)
    private let manager = CMMotionManager()
    #endif

    func start() {
        #if os(iOS)
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 10.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let gravity = motion?.gravity else { return }
            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.9)) {
                self.dx = CGFloat(gravity.x) * 80
                self.dy = CGFloat(-gravity.y) * 80
            }
        }
        #endif
        // On Mac there's no device motion — the background sits still.
    }

    func stop() {
        #if os(iOS)
        manager.stopDeviceMotionUpdates()
        #endif
    }
}
