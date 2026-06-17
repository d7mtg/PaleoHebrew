import SwiftUI

enum KeyboardStatus {
    static let keyboardID = "d7mtg.PaleoHebrew.PaleoProKeyboard"

    static var isSetUp: Bool {
        if Shared.defaults.bool(forKey: Shared.Key.keyboardHasLaunched) { return true }
        if let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] {
            return keyboards.contains(keyboardID)
        }
        return false
    }
}

/// Three-step keyboard setup wizard. Always starts at step 0 so the user can
/// re-enter the flow even if the keyboard was previously installed; advances
/// when iOS Settings is opened or when the user types a Paleo glyph.
struct KeyboardSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var step = 0
    @State private var testText = ""
    @FocusState private var testing: Bool

    private let totalSteps = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    StepDots(count: totalSteps, current: step).padding(.top, Spacing.md)
                    content
                        .id(step)
                        .transition(.materialize)
                        .padding(.top, Spacing.lg)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 160) // clear the bottom action bar
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Keyboard Setup")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .overlay(alignment: .bottom) { bottomBar }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .animation(Motion.smooth, value: step)
            .onChange(of: testText) { _, new in
                if new.unicodeScalars.contains(where: { Alphabet.isPaleoScalar($0) }) {
                    Haptics.success()
                    advance(to: 2)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            StepCard(symbol: "keyboard",
                     title: "Add the Keyboard",
                     message: "Open Settings → General → Keyboard → Keyboards → Add New Keyboard, then choose Paleo Hebrew. Turn on Allow Full Access for haptics.")
        case 1:
            VStack(spacing: Spacing.lg) {
                StepCard(symbol: "globe",
                         title: "Switch to Paleo Hebrew",
                         message: "Tap the field below, press the globe key on your keyboard until you reach Paleo Hebrew, then type any letter.")
                // Wrapping the field in a Button makes the entire card area
                // tappable and reliably focuses the underlying TextField —
                // SwiftUI's plain `.onTapGesture { focused = true }` is flaky
                // during sheet/step transitions.
                Button { testing = true } label: {
                    TextField("Type here…", text: $testText)
                        .focused($testing)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 34))
                        .padding(Spacing.lg)
                        .cardSurface()
                        .allowsHitTesting(testing)
                }
                .buttonStyle(.plain)
            }
            .task(id: step) {
                // Retry on a longer schedule — the sheet's animation
                // sometimes outruns the first focus attempt.
                for delay in [0.2, 0.5, 1.0] {
                    try? await Task.sleep(for: .seconds(delay))
                    if step == 1, testing == false { testing = true }
                }
            }
        default:
            StepCard(symbol: "checkmark",
                     title: "You're All Set",
                     tint: .green,
                     message: "Paleo Hebrew is ready. Switch to it anytime with the globe key in any app.")
        }
    }

    private var bottomBar: some View {
        ZStack(alignment: .bottom) {
            FadeUpBlur()
                .frame(height: 200)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            primaryButton
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case 0:
            Button {
                #if canImport(UIKit)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
                #endif
                advance(to: 1, delay: 1)
            } label: {
                Label("Open Keyboard Settings", systemImage: "arrow.up.forward.app")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .foregroundStyle(Color.onAccent)
        case 1:
            Button { advance(to: 2) } label: {
                Text("Skip")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        default:
            Button {
                Shared.defaults.set(true, forKey: Shared.Key.keyboardHasLaunched)
                Haptics.success()
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .foregroundStyle(Color.onAccent)
        }
    }

    private func advance(to next: Int, delay: Double = 0) {
        guard delay > 0 else {
            withAnimation(Motion.smooth) { step = next }
            return
        }
        Task {
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(Motion.smooth) { step = next }
        }
    }
}

private struct StepCard: View {
    let symbol: String
    var title: String
    var tint: Color = .accentColor
    var message: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: symbol)
                .font(.system(size: 56))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct StepDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.trackFill))
                    .frame(width: i == current ? 22 : 7, height: 7)
            }
        }
        .animation(Motion.smooth, value: current)
    }
}
