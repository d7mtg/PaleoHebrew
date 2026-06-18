import SwiftUI

/// "What's New" welcome screen, modeled on Apple's recent style (Freeform): the
/// real app icon centered on top, a left-aligned title above a short feature
/// list, and a concentric Continue button. Presented as a dismissible sheet by
/// `RootView`, shown once per app version.
struct WhatsNewView: View {
    var onContinue: () -> Void
    @State private var appeared = false

    // Three themes covering the whole journey since 1.0: the visual rebuild,
    // the per-letter depth, and how the app now lives across iOS.
    private let features: [Feature] = [
        .init(symbol: "sparkles", title: "A New Look",
              detail: "Rebuilt for iOS 26 with Liquid Glass, plus a redesigned Paleo Hebrew keyboard."),
        .init(symbol: "book.pages", title: "A Page for Every Letter",
              detail: "All 22 letters, each with its own page tracing how it became modern Hebrew, ready to share as a card."),
        .init(symbol: "apps.iphone", title: "At Home on iOS",
              detail: "Widgets, Shortcuts, Siri, Spotlight, Handoff, and iCloud sync across your devices."),
    ]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top space, so the whole section sits lower with room above the icon.
            Spacer(minLength: Spacing.xl)

            // The real app icon, centered, with room above and below it.
            Image("BrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.lg)

            // Left-aligned title; both lines the same size, left edge aligned to
            // the feature icons. Generous gap below the icon.
            VStack(alignment: .leading, spacing: 0) {
                Text("What's New in")
                    .font(.title.weight(.bold))
                Text("Paleo Pro \(appVersion)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.tint)
            }
            .padding(.top, 36)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            VStack(alignment: .leading, spacing: Spacing.xl) {
                ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                    FeatureRow(feature: feature, index: index)
                }
            }
            .padding(.top, Spacing.xl)

            Spacer(minLength: Spacing.xl)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        // Let iOS pin and position the Continue button in the bottom safe area;
        // it stays correct above the home indicator on every device size.
        .safeAreaInset(edge: .bottom) {
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
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.sm)
        }
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
    var index: Int = 0
    @State private var shown = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: feature.symbol)
                .font(.title2)
                .symbolRenderingMode(.monochrome) // solid teal, not two-tone
                .foregroundStyle(.tint)
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                // Title and detail are the same size; the difference is color.
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        // Simple fade-and-rise reveal. (No symbol draw effect: it left the
        // icons undrawn/invisible on device for symbols without draw support.)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : 8)
        .animation(.smooth(duration: 0.4), value: shown)
        .task {
            try? await Task.sleep(for: .seconds(0.12 + Double(index) * 0.12))
            shown = true
        }
    }
}

#Preview {
    WhatsNewView(onContinue: {})
}
