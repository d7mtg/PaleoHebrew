import UIKit
import SwiftUI
import AudioToolbox
import CoreText

// MARK: - Shared letterform preference (read from the App Group)

enum KBScribal {
    static let group = "group.com.d7mtg.PaleoHebrew"

    /// PostScript name for each ancient-script font id (mirrors ScribalFonts).
    private static let psName: [String: String] = [
        "PROTOCN": "Proto-Canaanite", "AHIRAM": "Phoenician-Ahiram",
        "GEZER": "Hebrew-Paleo-Gezer", "MESHA": "Hebrew-Paleo-Mesha",
        "BR_RKB": "Aramaic-Early-Br-Rkb", "AVIIBCE": "Aramaic-VIIBCE",
        "SILOAM": "Hebrew-Paleo-Siloam", "LACHISH": "Hebrew-Paleo-Lachish",
        "YEB": "Aramaic-Imperial-Yeb", "QUMRAN": "Hebrew-Paleo-Qumran",
        "Hebrew-Samaritan": "Hebrew-Samaritan",
    ]

    /// The raw chosen font id (empty string for default Unicode Paleo).
    static var selectedID: String {
        UserDefaults(suiteName: group)?.string(forKey: "paleoFontID") ?? ""
    }

    /// The chosen font's PostScript name, or nil for the default Unicode Paleo.
    static var selectedPSName: String? {
        let id = selectedID
        return id.isEmpty ? nil : psName[id]
    }

    private static var registered = false
    static func registerFonts() {
        guard !registered else { return }
        registered = true
        for ext in ["ttf", "TTF"] {
            for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [] {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

// MARK: - Host controller

final class KeyboardViewController: UIInputViewController {
    private var host: UIHostingController<PaleoKeyboardView>?
    private var lastFontID: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Record that the keyboard launched (consistent App Group name).
        UserDefaults(suiteName: KBScribal.group)?
            .set(true, forKey: "keyboardHasLaunched")

        KBScribal.registerFonts()

        // No custom backdrop — Apple provides the keyboard's background. Make
        // every layer clear so nothing competes with the system's surface.
        view.backgroundColor = .clear
        view.subviews.forEach { $0.backgroundColor = .clear }
        inputView?.backgroundColor = .clear
        inputView?.allowsSelfSizing = true

        let host = UIHostingController(rootView: PaleoKeyboardView(controller: self))
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        host.view.isOpaque = false
        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)
        self.host = host
        lastFontID = KBScribal.selectedID

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        let height = view.heightAnchor.constraint(equalToConstant: 240)
        height.priority = .defaultHigh
        height.isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The extension is cached across appearances; re-read the chosen font
        // and rebuild the SwiftUI view if the user changed it in the app.
        let current = KBScribal.selectedID
        if current != lastFontID {
            lastFontID = current
            host?.rootView = PaleoKeyboardView(controller: self)
        }
    }

    func insert(_ text: String) { textDocumentProxy.insertText(text) }
    func backspace() { textDocumentProxy.deleteBackward() }
    var contextBeforeInput: String? { textDocumentProxy.documentContextBeforeInput }
    var fullAccess: Bool { hasFullAccess }
    /// `true` only on devices where iOS doesn't already render a globe in the
    /// system area (Home-button iPhones, e.g. SE). On Face-ID phones the OS
    /// shows one for us, so we omit ours to avoid duplication.
    var systemShowsGlobe: Bool { !needsInputModeSwitchKey }
}

// MARK: - Data

private struct KeyCap: Identifiable {
    let modern: String
    let paleo: String
    var id: String { modern }
}

private enum KB {
    static let paleoFor: [String: String] = [
        "א": "𐤀", "ב": "𐤁", "ג": "𐤂", "ד": "𐤃", "ה": "𐤄", "ו": "𐤅",
        "ז": "𐤆", "ח": "𐤇", "ט": "𐤈", "י": "𐤉", "כ": "𐤊", "ך": "𐤊",
        "ל": "𐤋", "מ": "𐤌", "ם": "𐤌", "נ": "𐤍", "ן": "𐤍", "ס": "𐤎",
        "ע": "𐤏", "פ": "𐤐", "ף": "𐤐", "צ": "𐤑", "ץ": "𐤑", "ק": "𐤒",
        "ר": "𐤓", "ש": "𐤔", "ת": "𐤕",
    ]
    static func caps(_ moderns: [String]) -> [KeyCap] {
        moderns.map { KeyCap(modern: $0, paleo: paleoFor[$0] ?? $0) }
    }
    static let row1 = caps(["ק", "ר", "א", "ט", "ו", "ן", "ם", "פ"])      // 8
    static let row2 = caps(["ש", "ד", "ג", "כ", "ע", "י", "ח", "ל", "ך"]) // 9
    static let row3 = caps(["ז", "ס", "ב", "ה", "נ", "מ", "צ", "ת", "ץ"]) // 9

    // Spec: keys taller than wide (~1.4:1), tight h-spacing, looser v-spacing,
    // rows have natural widths and don't all stretch to fill the screen.
    static let keyWidth: CGFloat = 32
    static let keyHeight: CGFloat = 46
    static let backspaceWidth: CGFloat = 44
    static let hSpacing: CGFloat = 6
    static let vSpacing: CGFloat = 11
    static let keyRadius: CGFloat = 8   // was 6 — 2pt more rounded

    // Adaptive translucent keys — no opaque backdrop, no shadow, no texture.
    static let key = Color(uiColor: UIColor { t in
        // Dark: was 32% opacity, now 16% — half as bright, sits softer over the
        // system surface. Light: opaque white as before.
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.16)
            : UIColor.white
    })
    static let keyPressed = Color(uiColor: UIColor { t in
        // Dark pressed: was 55%, now 28% (half).
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.28)
            : UIColor(red: 0.84, green: 0.85, blue: 0.88, alpha: 1)
    })
    // Teal Return — chosen brand color, no texture, no shadow.
    static let accent = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.80, blue: 0.84, alpha: 1)
            : UIColor(red: 0.0, green: 0.62, blue: 0.745, alpha: 1)
    })
    static let accentPressed = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.86, blue: 0.90, alpha: 1)
            : UIColor(red: 0.0, green: 0.70, blue: 0.82, alpha: 1)
    })
    /// Black text on the teal Return in dark mode (white-on-teal fails contrast).
    static let accentText = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? .black : .white
    })
}

// MARK: - Keyboard view

private struct PaleoKeyboardView: View {
    let controller: KeyboardViewController
    @State private var paleoPrimary = true
    @State private var lastSpaceTime: Date?

    var body: some View {
        VStack(spacing: KB.vSpacing) {
            row(KB.row1, trailing: .backspace)
            row(KB.row2)
            row(KB.row3)
            functionRow
        }
        .padding(.top, 1)            // tighter on top
        .padding(.bottom, 0)         // no bottom padding — Apple's surface handles it
        .padding(.horizontal, 5)     // a touch more breathing room on the sides
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }

    private enum RowTrailing { case none, backspace }

    /// Letter rows fill the full width: each key flexes equally so the row
    /// hugs the edges. Backspace gets a slightly wider fixed slot on row 1.
    private func row(_ caps: [KeyCap], trailing: RowTrailing = .none) -> some View {
        HStack(spacing: KB.hSpacing) {
            ForEach(caps) { cap in
                LetterKey(cap: cap, paleoPrimary: paleoPrimary) { insert(cap.paleo) }
            }
            if trailing == .backspace {
                KeyButton(width: KB.backspaceWidth,
                          action: { controller.backspace(); play(1155); haptic(.light) },
                          onRepeat: { controller.backspace() }) {
                    Image(systemName: "delete.left").font(.system(size: 20, weight: .medium))
                }
            }
        }
    }

    private var functionRow: some View {
        HStack(spacing: KB.hSpacing) {
            // Globe — only shown when the system doesn't already render one
            // (Home-button phones). Transparent, icon-only — no key background.
            if !controller.systemShowsGlobe {
                Image(systemName: "globe")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: KB.backspaceWidth, height: KB.keyHeight)
                    .contentShape(Rectangle())
                    .overlay(NextKeyboardButton(controller: controller))
            }

            KeyButton(width: KB.backspaceWidth, action: {
                // Slightly longer & smoother so the dual-letter morph reads.
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    paleoPrimary.toggle()
                }
                haptic(.medium); play(1156)
            }) {
                Image(systemName: "arrow.2.squarepath").font(.system(size: 19, weight: .medium))
            }

            // Space — flexes to fill the remaining width. No label (the system
            // space bar has none either).
            KeyButton(action: { space() }) {
                Color.clear
            }

            KeyButton(width: 88,
                      fill: KB.accent, pressedFill: KB.accentPressed, foreground: KB.accentText,
                      action: { controller.insert("\n"); lastSpaceTime = nil; play(1156); haptic(.light) }) {
                Image(systemName: "return").font(.system(size: 19, weight: .semibold))
            }
        }
    }

    private func insert(_ s: String) {
        lastSpaceTime = nil
        controller.insert(s); play(1104); haptic(.light)
    }

    /// Double-tap space inserts ". " when a space already precedes the caret.
    private func space() {
        let now = Date()
        if controller.contextBeforeInput?.hasSuffix(" ") == true,
           let last = lastSpaceTime, now.timeIntervalSince(last) < 0.4 {
            controller.backspace()
            controller.insert(". ")
            lastSpaceTime = nil
        } else {
            controller.insert(" ")
            lastSpaceTime = now
        }
        play(1104); haptic(.light)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard controller.fullAccess else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    private func play(_ id: SystemSoundID) { AudioServicesPlaySystemSound(id) }
}

// MARK: - Keys

private struct LetterKey: View {
    let cap: KeyCap
    let paleoPrimary: Bool
    let action: () -> Void

    // Each glyph has its own resting corner so the two letters never cross
    // paths on swap — Paleo rests bottom-left, Modern rests top-right.
    // Whichever is "primary" sits at the center.
    private let cornerScale: CGFloat = 0.4
    private let cornerOffsetX: CGFloat = 10
    private let cornerOffsetY: CGFloat = 14

    /// PostScript name of the chosen ancient font, or nil for Unicode Paleo.
    private var scribalPS: String? { KBScribal.selectedPSName }

    var body: some View {
        KeyButton(action: action) {
            ZStack {
                glyph(paleoSide: true, isThisLetterPrimary: paleoPrimary, restingAt: .bottomLeading)
                glyph(paleoSide: false, isThisLetterPrimary: !paleoPrimary, restingAt: .topTrailing)
            }
        }
        .accessibilityLabel("\(cap.paleo), \(cap.modern)")
    }

    private enum RestCorner { case bottomLeading, topTrailing }

    private func glyph(paleoSide: Bool, isThisLetterPrimary primary: Bool, restingAt corner: RestCorner) -> some View {
        let dx: CGFloat, dy: CGFloat
        switch corner {
        case .bottomLeading: dx = -cornerOffsetX; dy =  cornerOffsetY
        case .topTrailing:   dx =  cornerOffsetX; dy = -cornerOffsetY
        }
        // The Paleo side draws in the chosen ancient font (which is keyed on
        // the Hebrew letter); otherwise the system Unicode Paleo glyph.
        let text: String
        let font: Font
        if paleoSide, let ps = scribalPS {
            text = cap.modern
            font = .custom(ps, size: 22)
        } else if paleoSide {
            text = cap.paleo
            font = .system(size: 22, weight: .regular)
        } else {
            text = cap.modern
            font = .system(size: 22, weight: .regular)
        }
        return Text(text)
            .font(font)
            .scaleEffect(primary ? 1.0 : cornerScale)
            .offset(x: primary ? 0 : dx, y: primary ? 0 : dy)
            .foregroundStyle(primary ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
    }
}

/// One key — flat rounded rectangle, no shadow, no texture. Optional repeat-on-hold.
/// Pass `width: nil` to flex (`maxWidth: .infinity`); a number pins a fixed width.
private struct KeyButton<Label: View>: View {
    var width: CGFloat? = nil
    var fill: Color = KB.key
    var pressedFill: Color = KB.keyPressed
    var foreground: Color = Color(uiColor: .label)
    let action: () -> Void
    var onRepeat: (() -> Void)? = nil
    @ViewBuilder var label: Label

    @State private var pressed = false
    @State private var repeatTimer: Timer?

    @ViewBuilder
    private var sized: some View {
        let body = ZStack {
            RoundedRectangle(cornerRadius: KB.keyRadius, style: .continuous)
                .fill(pressed ? pressedFill : fill)
            label.foregroundStyle(foreground)
        }
        if let width {
            body.frame(width: width, height: KB.keyHeight)
        } else {
            body.frame(maxWidth: .infinity, minHeight: KB.keyHeight, maxHeight: KB.keyHeight)
        }
    }

    var body: some View {
        sized
            .scaleEffect(pressed ? 1.10 : 1)
            // Press DOWN is instant (animation nil); only the spring-back on
            // release is animated, so the highlight appears the moment you touch.
            .animation(pressed ? nil : .spring(response: 0.22, dampingFraction: 0.7), value: pressed)
            .zIndex(pressed ? 1 : 0)
            .contentShape(RoundedRectangle(cornerRadius: KB.keyRadius, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    if onRepeat != nil {
                        action()
                        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                            repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.11, repeats: true) { _ in onRepeat?() }
                        }
                    }
                }
                .onEnded { _ in
                    pressed = false
                    repeatTimer?.invalidate(); repeatTimer = nil
                    if onRepeat == nil { action() }
                }
        )
    }
}

// MARK: - Globe button bridged to UIKit for tap-advance + hold-list

private struct NextKeyboardButton: UIViewRepresentable {
    let controller: UIInputViewController
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .clear
        button.addTarget(controller,
                         action: #selector(UIInputViewController.handleInputModeList(from:with:)),
                         for: .allTouchEvents)
        return button
    }
    func updateUIView(_ uiView: UIButton, context: Context) {}
}
