import SwiftUI

/// Apple-style "What's New" welcome screen: app mark, a short feature list with
/// SF Symbols, and a single prominent Continue button.
///
/// NOTE: currently shown on every launch for review. Before release, gate it to
/// first-launch-per-version via the `whatsNewSeenVersion` flag below.
struct WhatsNewView: View {
    var onContinue: () -> Void
    @State private var appeared = false

    private let features: [Feature] = [
        .init(symbol: "sparkles", title: "A New Look",
              detail: "Rebuilt for iOS 26 with Liquid Glass across every screen."),
        .init(symbol: "keyboard", title: "Redesigned Keyboard",
              detail: "Taller keys, dual-script labels, and instant feedback."),
        .init(symbol: "gamecontroller", title: "Learn and Play",
              detail: "Browse all 22 letters, then test yourself with a quick quiz."),
        .init(symbol: "scroll", title: "A Richer Story",
              detail: "Real inscriptions you can zoom into, copy, and explore."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)

            VStack(spacing: Spacing.md) {
                Image("AppIconMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 58)
                    .foregroundStyle(.tint)

                VStack(spacing: 4) {
                    Text("What's New in")
                        .font(.largeTitle.weight(.bold))
                    Text("Paleo Pro")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.tint)
                }
                .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer(minLength: Spacing.xl)

            VStack(alignment: .leading, spacing: Spacing.xl) {
                ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                    FeatureRow(feature: feature)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.smooth(duration: 0.5).delay(0.15 + Double(index) * 0.08), value: appeared)
                }
            }
            .padding(.horizontal, Spacing.sm)

            Spacer(minLength: Spacing.xl)

            Button {
                Haptics.impact(.light)
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .foregroundStyle(Color.onAccent)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            withAnimation(.smooth(duration: 0.5)) { appeared = true }
        }
    }

    struct Feature: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }
}

private struct FeatureRow: View {
    let feature: WhatsNewView.Feature

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            Image(systemName: feature.symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    WhatsNewView(onContinue: {})
}
