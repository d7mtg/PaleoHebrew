import SwiftUI

/// A one-shot burst of Paleo glyphs — a thematic confetti celebration.
/// Each piece rises, arcs, spins, then falls and fades. The animation is
/// driven by an explicit `trigger` so it reliably fires the moment the view
/// is inserted (a plain `repeating: false` animator can fail to start when the
/// view appears conditionally).
struct ConfettiView: View {
    var count = 36

    private let glyphs = Alphabet.letters.map(\.paleo)
    // Brand-coherent teal family with a couple of warm accents for sparkle.
    private let palette: [Color] = [.teal, .cyan, .mint, .blue, .indigo, .orange, .yellow]

    @State private var pieces: [Piece] = []
    @State private var fire = false

    struct Piece: Identifiable {
        let id = UUID()
        let glyph: String
        let color: Color
        let startX: CGFloat   // horizontal start, fraction of width
        let dx: CGFloat
        let rise: CGFloat
        let fall: CGFloat
        let spin: Double
        let size: CGFloat
        let delay: Double
    }

    struct Values {
        var y: CGFloat = 0
        var progressX: CGFloat = 0
        var opacity: Double = 0
        var rotation: Double = 0
        var scale: CGFloat = 0.4
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Text(piece.glyph)
                        .font(.system(size: piece.size, weight: .semibold))
                        .foregroundStyle(piece.color)
                        .keyframeAnimator(initialValue: Values(), trigger: fire) { view, value in
                            view
                                .opacity(value.opacity)
                                .scaleEffect(value.scale)
                                .rotationEffect(.degrees(value.rotation))
                                .offset(x: piece.dx * value.progressX, y: value.y)
                        } keyframes: { _ in
                            KeyframeTrack(\.y) {
                                LinearKeyframe(0, duration: piece.delay)
                                SpringKeyframe(-piece.rise, duration: 0.5, spring: .bouncy)
                                CubicKeyframe(piece.fall, duration: 1.0)
                            }
                            KeyframeTrack(\.progressX) {
                                LinearKeyframe(0, duration: piece.delay)
                                LinearKeyframe(1, duration: 1.5)
                            }
                            KeyframeTrack(\.opacity) {
                                LinearKeyframe(0, duration: piece.delay)
                                LinearKeyframe(1, duration: 0.12)
                                LinearKeyframe(1, duration: 1.0)
                                LinearKeyframe(0, duration: 0.4)
                            }
                            KeyframeTrack(\.rotation) {
                                LinearKeyframe(0, duration: piece.delay)
                                LinearKeyframe(piece.spin, duration: 1.5)
                            }
                            KeyframeTrack(\.scale) {
                                LinearKeyframe(0.4, duration: piece.delay)
                                SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                                LinearKeyframe(0.75, duration: 1.0)
                            }
                        }
                        .position(x: geo.size.width * piece.startX, y: geo.size.height * 0.42)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            spawn()
            // Kick the trigger on the next runloop so the animator starts from
            // its initial values and animates to the keyframes.
            DispatchQueue.main.async { fire.toggle() }
        }
    }

    private func spawn() {
        pieces = (0..<count).map { i in
            Piece(
                glyph: glyphs.randomElement()!,
                color: palette.randomElement()!,
                startX: .random(in: 0.2...0.8),
                dx: .random(in: -200...200),
                rise: .random(in: 120...300),
                fall: .random(in: 500...820),
                spin: .random(in: -320...320),
                size: .random(in: 22...46),
                delay: Double(i) / Double(count) * 0.25
            )
        }
    }
}
