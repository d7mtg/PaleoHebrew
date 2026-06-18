import SwiftUI

/// A shareable card for one letter. It deliberately mirrors what the letter
/// looks like inside the app's `LetterSheet`: the Paleo + modern pairing on top,
/// then the same rail-and-dots "How it became Hebrew" timeline, then a Paleo Pro
/// / App Store footer. Rendered to an image via `ImageRenderer` (see `render`).
///
/// The timeline here is a static rendition of `LetterSheet`'s — the in-app rows
/// reveal with an `onAppear` animation that would snapshot at opacity 0 in
/// `ImageRenderer`, so the visuals are reproduced without the animation gating.
struct LetterShareCard: View {
    let letter: PaleoLetter
    @Environment(\.colorScheme) private var scheme

    /// The same curated lineage the sheet shows by default, ending at modern.
    private var nodes: [CardTimelineRow.Node] {
        ScribalFonts.timelineDefault.map { .script($0) } + [.modern]
    }

    /// Explicit brand teal — `ImageRenderer` doesn't resolve the asset-catalog
    /// AccentColor (it falls back to system blue), so the card sets it directly.
    private var teal: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.317, green: 0.859, blue: 0.872, alpha: 1)
                : UIColor(red: 0.0, green: 0.621, blue: 0.745, alpha: 1)
        })
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            hero
            Divider().opacity(0.5)
            evolution
            footer
        }
        // Wider than the default sheet so the long script names ("Imperial
        // Aramaic · Elephantine") sit on one line and the footer (brand + badge)
        // fits side by side.
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, 28)
        .frame(width: 430)
        .background(Color.appBackground)
    }

    // MARK: Hero — the same pairing the sheet shows at the top.

    private var hero: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xl) {
                PaleoGlyph(text: letter.paleo, size: 80)
                    .foregroundStyle(teal)
                Text(letter.modern)
                    .font(.system(size: 80))
            }
            .frame(height: 100)
            Text(letter.name)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: Evolution — the sheet's rail-and-dots timeline, static.

    private var evolution: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How it became Hebrew")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, Spacing.md)

            ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                CardTimelineRow(
                    node: node,
                    modern: letter.modern,
                    isFirst: i == 0,
                    isLast: i == nodes.count - 1,
                    teal: teal
                )
            }
        }
    }

    // MARK: Footer — Paleo Pro mark + the App Store badge.

    private var footer: some View {
        VStack(spacing: Spacing.md) {
            Divider().opacity(0.5)
            HStack(spacing: Spacing.md) {
                appIconMark
                VStack(alignment: .leading, spacing: 1) {
                    Text("Paleo Pro").font(.headline)
                    Text("Learn the ancient Hebrew alphabet")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                AppStoreBadge().frame(height: 46)
            }
        }
        .padding(.top, 2)
    }

    /// The real app icon, resolved for the card's color scheme (ImageRenderer
    /// doesn't reliably apply the dark-appearance trait, so it's picked by hand).
    private var appIconMark: some View {
        Group {
            if let base = UIImage(named: "BrandIcon"),
               let img = base.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)) ?? UIImage(named: "BrandIcon") {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                Image("BrandIcon").resizable().scaledToFit()
            }
        }
        .frame(width: 52, height: 52)
    }
}

/// One timeline node + the rail, matching `LetterSheet`'s `TimelineRow` look but
/// without the staged appear animation (so it renders fully in a snapshot).
private struct CardTimelineRow: View {
    enum Node: Identifiable {
        case script(ScribalFont)
        case modern
        var id: String {
            switch self {
            case .script(let f): return f.id
            case .modern: return "modern"
            }
        }
    }

    let node: Node
    let modern: String
    let isFirst: Bool
    let isLast: Bool
    let teal: Color

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            railColumn
            glyph
                .frame(width: 56, height: 56)
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(era).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 64)
    }

    private var railColumn: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle().fill(railColor).frame(width: 2).opacity(isFirst ? 0 : 1)
                Rectangle().fill(railColor).frame(width: 2).opacity(isLast ? 0 : 1)
            }
            Circle()
                .fill(dotColor)
                .frame(width: isModern ? 12 : 9, height: isModern ? 12 : 9)
        }
        .frame(width: 14)
    }

    @ViewBuilder
    private var glyph: some View {
        switch node {
        case .script(let f):
            // Culmus fonts are keyed on the Hebrew range, so feed the modern
            // letter; the font draws that era's shape (exactly as the sheet does).
            Text(modern).font(.custom(f.postScriptName, size: 40))
        case .modern:
            Text(modern).font(.system(size: 40, weight: .semibold)).foregroundStyle(teal)
        }
    }

    private var isModern: Bool { if case .modern = node { return true }; return false }

    private var title: String {
        switch node {
        case .script(let f): return f.displayName
        case .modern: return "Modern Hebrew"
        }
    }

    private var era: String {
        switch node {
        case .script(let f): return f.era
        case .modern: return "today"
        }
    }

    private var dotColor: Color {
        switch node {
        case .modern: return teal
        case .script(let f): return f.isAncientHand ? teal : .secondary
        }
    }

    private var railColor: Color { Color.secondary.opacity(0.25) }
}

/// The official "Download on the App Store" badge if bundled as `AppStoreBadge`,
/// otherwise a faithful rebuild of Apple's black badge. Drop the official asset
/// into the `AppStoreBadge` image set to use Apple's exact artwork instead.
struct AppStoreBadge: View {
    @Environment(\.colorScheme) private var scheme
    private let height: CGFloat = 44
    private var corner: CGFloat { 8.5 }

    var body: some View {
        if let badge = officialBadge {
            Image(uiImage: badge).resizable().scaledToFit()
        } else {
            lockup
        }
    }

    /// The official Apple badge asset, explicitly resolved for the current color
    /// scheme (black on light, white on dark). ImageRenderer doesn't reliably
    /// apply the dark-appearance trait, so the variant is picked by hand.
    private var officialBadge: UIImage? {
        guard let base = UIImage(named: "AppStoreBadge") else { return nil }
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        return base.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: style)) ?? base
    }

    /// Apple's badge is a fixed lockup: the Apple mark, then "Download on the"
    /// above "App Store", on a black rounded rectangle with a hairline border.
    private var lockup: some View {
        HStack(spacing: 7) {
            Image(systemName: "apple.logo")
                .font(.system(size: 23))
            VStack(alignment: .leading, spacing: -1) {
                Text("Download on the")
                    .font(.system(size: 8.5, weight: .medium))
                Text("App Store")
                    .font(.system(size: 19.5, weight: .semibold))
            }
        }
        .foregroundStyle(.white)
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .frame(height: height)
        .background(.black, in: .rect(cornerRadius: corner))
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(.white.opacity(0.4), lineWidth: 0.75)
        )
    }
}

#if canImport(UIKit)
import UIKit

extension LetterShareCard {
    /// Render the card to an image in the given color scheme (no status bar).
    /// `scale` defaults to 2 (plenty sharp for a shared image, and far cheaper
    /// on the main thread than 3, which matters since the sheet renders this
    /// for the current letter as you browse).
    @MainActor
    static func render(letter: PaleoLetter, scheme: ColorScheme, scale: CGFloat = 2) -> UIImage? {
        let renderer = ImageRenderer(
            content: LetterShareCard(letter: letter)
                .environment(\.colorScheme, scheme)
        )
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
#endif
