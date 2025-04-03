import SwiftUI
import os.log

fileprivate func systemUIColor(for colorName: String) -> UIColor {
    switch colorName {
    case "neutral": return .systemGray3
    case "blue": return .systemBlue
    case "green": return .systemGreen
    case "orange": return .systemOrange
    case "pink": return .systemPink
    case "purple": return .systemPurple
    case "red": return .systemRed
    case "teal": return .systemTeal
    case "indigo": return .systemIndigo
    default: return .systemTeal
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - FakeAppIconView

struct FakeAppIconView: View {
    @Binding var showDebug: Bool
    @Environment(\.colorScheme) private var colorScheme
    let selectedAccentColor: String

    @State private var offset = CGSize.zero
    @State private var isJiggling = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    
    // Get accent color using the passed parameter
    private var accentColor: Color {
        Color(uiColor: systemUIColor(for: selectedAccentColor))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Make only the icon itself draggable
            iconBody
                .contentShape(Rectangle())
                .offset(offset)
                .rotationEffect(Angle(degrees: isJiggling ? 2 : 0))
                .animation(
                    isJiggling ?
                        Animation.easeInOut(duration: 0.15)
                            .repeatForever(autoreverses: true) :
                        .default,
                    value: isJiggling
                )
                .gesture(dragGesture)
                .onLongPressGesture(minimumDuration: 0.5) {
                    withAnimation {
                        isJiggling.toggle()
                    }
                }
                .contextMenu {
                    contextMenu()
                }

            if isJiggling {
                deleteButton
            }
        }
        .frame(width: 72, height: 72)
        .alert("LOL", isPresented: $showDeleteAlert) {
            Button("Fine", role: .cancel) {}
        } message: {
            Text("You can't actually delete me ")
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [URL(string: "https://apps.apple.com/us/app/paleo-pro/id6743683727")!])
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                self.offset = gesture.translation
                if !self.isJiggling {
                    withAnimation {
                        self.isJiggling = true
                    }
                }
            }
            .onEnded { _ in
                withAnimation(.spring()) {
                    self.offset = .zero
                }
            }
    }
    
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "minus.circle.fill")
                .font(.title2)
                .background(Color.white.clipShape(Circle()))
        }
        .offset(x: -10, y: -10)
    }

    private var iconBody: some View {
        ZStack {
            iconBackground
            iconGlossOverlay
            iconGlyph
        }
    }
    
    private var iconBackground: some View {
        Group {
            if colorScheme == .dark {
                darkModeBackground
            } else {
                lightModeBackground
            }
        }
    }
    
    private var darkModeBackground: some View {
        let darkColors: [Color] = [
            Color(hex: "#313131"),
            Color(hex: "#141414")
        ]
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: darkColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 72, height: 72)
    }
    
    private var lightModeBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(accentColor)
            .frame(width: 72, height: 72)
    }
    
    private var iconGlossOverlay: some View {
        Group {
            if colorScheme == .light {
                lightModeGloss
            } else {
                darkModeGloss
            }
        }
    }
    
    private var lightModeGloss: some View {
        let glossColors: [Color] = [
            Color.white.opacity(0.4),
            Color.white.opacity(0.0)
        ]
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: glossColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 72, height: 72)
    }
    
    private var darkModeGloss: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.clear)
            .frame(width: 72, height: 72)
    }
    
    private var iconGlyph: some View {
        Group {
            if colorScheme == .dark {
                darkModeGlyph
            } else {
                lightModeGlyph
            }
        }
    }
    
    private var darkModeGlyph: some View {
        Group {
            if selectedAccentColor == "neutral" {
                neutralDarkModeGlyph
            } else {
                coloredDarkModeGlyph
            }
        }
    }
    
    private var neutralDarkModeGlyph: some View {
        Image("paleoLogo")
            .resizable()
            .renderingMode(.template)
            .foregroundColor(.white)
            .frame(width: 48, height: 36)
    }
    
    private var coloredDarkModeGlyph: some View {
        ZStack {
            // Base colored glyph
            baseGlyph(color: accentColor)
            
            // Soft white gradient overlay on the glyph
            baseGlyph(color: .white)
                .opacity(1.0)
                .mask(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    private var lightModeGlyph: some View {
        baseGlyph(color: .white)
    }
    
    private func baseGlyph(color: Color) -> some View {
        Image("paleoLogo")
            .resizable()
            .renderingMode(.template)
            .foregroundColor(color)
            .frame(width: 48, height: 36)
    }

    @ViewBuilder
    private func contextMenu() -> some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("Delete App", systemImage: "trash")
        }
        Button {
            showShareSheet = true
        } label: {
            Label("Share App", systemImage: "square.and.arrow.up")
        }
        Button {
            showDebug.toggle()
        } label: {
            Label("Show Debug Menu", systemImage: "ladybug")
        }
    }
}

// MARK: - ActivityView

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.d7mtg.PaleoHebrew", category: "AppIconChanger")

// MARK: - SettingsView

struct SettingsView: View {
    @AppStorage("selectedAccentColor") private var selectedAccentColor: String = "teal"
    @State private var showIconChangeError = false
    @State private var iconChangeErrorMessage = ""
    @State private var iconDebugInfo = ""
    @State private var showDebugInfo = false
    @State private var showKeyboardSetupSheet = false
    @State private var showKeyboardTestSheet = false
    @State private var keyboardIsSetup = false
    @State private var showTextField = false
    
    var body: some View {
        NavigationView {
            Form {
                headerSection
                accentColorSection
                
                if showDebugInfo {
                    debugInfoSection
                }
                
                keyboardSection
                aboutSection
                footerSection
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showIconChangeError) {
                Alert(
                    title: Text("Icon Change Failed"),
                    message: Text(iconChangeErrorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showKeyboardSetupSheet) {
                KeyboardTestView(isSetup: $keyboardIsSetup)
            }
            .sheet(isPresented: $showKeyboardTestSheet) {
                KeyboardTestView(isSetup: $keyboardIsSetup)
            }
        }
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
    }
    
    // MARK: - Section Views
    
    private var headerSection: some View {
        Section {
            ZStack(alignment: .top) {
                // Background and text container
                headerContent
                
                // App icon positioned independently
                FakeAppIconView(showDebug: $showDebugInfo, selectedAccentColor: selectedAccentColor)
                    .padding(.top, 12)
            }
        }
        .listRowBackground(Color(.systemBackground))
    }
    
    private var headerContent: some View {
        VStack(spacing: 12) {
            // Placeholder for the icon space
            Color.clear
                .frame(width: 72, height: 72)
                .padding(.top, 12)
            
            HStack(spacing: 8) {
                Text("Paleo Pro")
                    .font(.title2)
                    .bold()
            }
            
            Text("Learn the ancient Paleo-Hebrew alphabet with intuitive lessons and games.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .onTapGesture(count: 3) {
            // Triple tap to show debug info
            gatherDebugInfo()
            showDebugInfo = true
        }
    }
    
    private var accentColorSection: some View {
        Section(header: Text("Accent color")) {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    accentColorOptions
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var accentColorOptions: some View {
        let colors = ["teal", "blue", "neutral", "green", "orange", "pink", "purple", "red", "indigo"]
        
        return HStack(spacing: 12) {
            ForEach(colors, id: \.self) { color in
                accentColorCircle(for: color)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func accentColorCircle(for color: String) -> some View {
        let circleSize: CGFloat = 28
        let strokeOpacity = selectedAccentColor == color ? 0.6 : 0.2
        
        return Circle()
            .fill(Color(uiColor: systemUIColor(for: color)))
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(strokeOpacity), lineWidth: 2)
            )
            .padding(4)
            .onTapGesture {
                handleAccentColorTap(color)
            }
            .accessibilityLabel(Text("\(color.capitalized)"))
    }
    
    private var debugInfoSection: some View {
        Section(header: Text("Debug Info")) {
            Text(iconDebugInfo)
                .font(.system(.footnote, design: .monospaced))
            
            debugButtons
        }
    }
    
    private var debugButtons: some View {
        Group {
            Button("Test Icon Change (Red)") {
                testIconChange()
            }
            
            Button("Refresh Debug Info") {
                gatherDebugInfo()
            }
            
            Button("Close Debug Info") {
                showDebugInfo = false
            }
            
            Button("Copy Logs to Clipboard") {
                UIPasteboard.general.string = iconDebugInfo
            }

            Button("Share Logs") {
                shareDebugLogs()
            }
        }
    }
    
    private var keyboardSection: some View {
        Section(header: Text("Keyboard")) {
            Button(action: handleKeyboardButtonTap) {
                HStack {
                    Image(systemName: keyboardIsSetup ? "keyboard.fill" : "keyboard")
                        .foregroundColor(Color(uiColor: systemUIColor(for: selectedAccentColor)))
                    
                    Text(keyboardIsSetup ? "Paleo Hebrew Keyboard is Set Up" : "Set Up Paleo Hebrew Keyboard")
                    
                    Spacer()
                    
                    if keyboardIsSetup {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            Link(destination: URL(string: "https://aleph.d7mtg.com")!) {
                Label("More tools like this one", systemImage: "character.book.closed.he")
            }
            
            Link(destination: URL(string: "https://d7mtg.com/privacy")!) {
                Label("Privacy Policy", systemImage: "lock")
            }
        }
    }
    
    private var footerSection: some View {
        Section {
            HStack(spacing: 0) {
                Text("Designed by ")
                    .font(.system(size: 12, design: .monospaced))
                Text("D7mtg")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(uiColor: systemUIColor(for: selectedAccentColor)))
                    .onTapGesture {
                        if let url = URL(string: "https://d7mtg.com?utm_source=app&utm_medium=settings&utm_campaign=app_icon") {
                            UIApplication.shared.open(url)
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Helper Methods
    
    private func handleAccentColorTap(_ color: String) {
        selectedAccentColor = color
        UINavigationBar.appearance().tintColor = systemUIColor(for: color)
        changeAppIcon(to: color)
    }
    
    private func handleKeyboardButtonTap() {
        if keyboardIsSetup {
            // If already set up, show the test sheet
            showKeyboardTestSheet = true
        } else {
            // If not set up, show setup instructions
            showKeyboardSetupSheet = true
        }
    }
    
    private func shareDebugLogs() {
        let activityVC = UIActivityViewController(activityItems: [iconDebugInfo], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func handleOnAppear() {
        let defaults = UserDefaults(suiteName: "group.com.d7mtg.paleopro")
        keyboardIsSetup = defaults?.bool(forKey: "keyboardHasLaunched") ?? false

        // Log key info when view appears
        logger.info("App launched. Supports alternate icons: \(UIApplication.shared.supportsAlternateIcons)")
        logger.info("Current icon name: \(UIApplication.shared.alternateIconName ?? "default")")
        
        // Add notification observer for keyboard test
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowKeyboardTest"), object: nil, queue: .main) { _ in
            showKeyboardTestSheet = true
        }
    }
    
    private func handleOnDisappear() {
        // Remove the observer when view disappears
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShowKeyboardTest"), object: nil)
    }
    
    // Gather debug information
    private func gatherDebugInfo() {
        var info = ""
        
        // System information
        info += "iOS Version: \(UIDevice.current.systemVersion)\n"
        info += "Device: \(UIDevice.current.model)\n"
        info += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n\n"
        
        // App icon information
        info += "Supports alternate icons: \(UIApplication.shared.supportsAlternateIcons)\n"
        info += "Current icon name: \(UIApplication.shared.alternateIconName ?? "default")\n\n"
        
        // Info.plist configuration
        let infoPlistPath = Bundle.main.url(forResource: "Info", withExtension: "plist")
        info += "Info.plist path: \(infoPlistPath?.absoluteString ?? "Not found")\n"
        
        // Try to read CFBundleIcons from Info.plist
        if let infoDictionary = Bundle.main.infoDictionary {
            if let iconsDict = infoDictionary["CFBundleIcons"] as? [String: Any] {
                info += "CFBundleIcons found in Info.plist\n"
                
                if let alternateIcons = iconsDict["CFBundleAlternateIcons"] as? [String: Any] {
                    info += "Alternate icons defined: \(alternateIcons.keys.joined(separator: ", "))\n"
                } else {
                    info += "No CFBundleAlternateIcons found in Info.plist\n"
                }
            } else {
                info += "No CFBundleIcons found in Info.plist\n"
            }
        }
        
        if let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plistData = FileManager.default.contents(atPath: plistPath),
           let plistString = String(data: plistData, encoding: .utf8) {
            info += "\nInfo.plist contents:\n\(plistString)\n"
        }
        
        // Bundle path
        info += "\nBundle path: \(Bundle.main.bundlePath)\n"
        
        iconDebugInfo = info
    }
    
    // Test function to try a specific icon change
    private func testIconChange() {
        let testIconName = "AppIcon-red" // Test with this specific icon
        
        logger.info("Testing direct icon change to: \(testIconName)")
        
        UIApplication.shared.setAlternateIconName(testIconName) { error in
            if let error = error {
                logger.error("Test icon change failed: \(error.localizedDescription)")
                iconChangeErrorMessage = "Test failed: \(error.localizedDescription)"
                showIconChangeError = true
            } else {
                logger.info("Test icon change succeeded!")
                // Update debug info after successful change
                gatherDebugInfo()
            }
        }
    }
    
    // Function to change the app icon based on selected color with enhanced logging
    private func changeAppIcon(to color: String) {
        logger.info("Attempting to change icon to color: \(color)")

        guard UIApplication.shared.supportsAlternateIcons else {
            logger.error("Device doesn't support alternate icons")
            iconChangeErrorMessage = "This device doesn't support alternate app icons"
            showIconChangeError = true
            return
        }

        let iconName: String? = {
            switch color {
            case "teal": return nil // default
            case "blue": return "AppIcon-blue"
            case "neutral": return "AppIcon-neutral"
            case "green": return "AppIcon-green"
            case "orange": return "AppIcon-orange"
            case "pink": return "AppIcon-pink"
            case "purple": return "AppIcon-purple"
            case "red": return "AppIcon-red"
            case "indigo": return "AppIcon-indigo"
            default: return nil
            }
        }()
        let currentIcon = UIApplication.shared.alternateIconName

        if currentIcon == iconName {
            logger.info("Icon already set to \(iconName ?? "default"), no change needed")
            return
        }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                logger.error("Icon change failed: \(error.localizedDescription)")
                iconChangeErrorMessage = "Couldn't change app icon: \(error.localizedDescription)"
                showIconChangeError = true
            } else {
                logger.info("Successfully changed app icon to \(iconName ?? "default")")
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                gatherDebugInfo()
            }
        }
    }
}

// MARK: - AccentColorPicker

struct AccentColorPicker: View {
    @Binding var selectedColor: String
    let colors = ["teal", "blue", "neutral", "green", "orange", "pink", "purple", "red", "indigo"]
    
    var body: some View {
        List {
            ForEach(colors, id: \.self) { color in
                colorRow(for: color)
            }
        }
        .navigationTitle("Accent Color")
    }
    
    private func colorRow(for color: String) -> some View {
        HStack {
            Circle()
                .fill(Color(color))
                .frame(width: 24, height: 24)
            Text(color.capitalized)
            Spacer()
            if selectedColor == color {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedColor = color
        }
    }
}

// MARK: - KeyboardTestView

struct KeyboardTestView: View {
    enum KeyboardStep {
        case addKeyboard
        case showKeyboard
        case complete
    }

    @State private var step: KeyboardStep = .addKeyboard
    @State private var testInput = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isTestingKeyboard = false
    @State private var showTextField = false
    @Binding var isSetup: Bool
    
    init(isSetup: Binding<Bool>? = nil) {
        self._isSetup = isSetup ?? .constant(true)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                }

                Spacer()

                mainContentSection
                
                Spacer()

                bottomButtonsSection
            }
            .padding()
            .navigationTitle("Keyboard Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: handleOnAppear)
            .onChange(of: testInput, perform: handleInputChange)
        }
    }
    
    // MARK: - Content Sections
    
    private var mainContentSection: some View {
        VStack(spacing: 20) {
            headerImage
            stepIndicator
            instructionTexts
            
            if step != .addKeyboard {
                textInputField
            }
        }
    }
    
    private var headerImage: some View {
        Image(systemName: step == .showKeyboard ? "globe" : "keyboard")
            .font(.system(size: 40))
            .foregroundColor(.accentColor)
            .padding()
            .background(Circle().fill(Color.accentColor.opacity(0.1)))
    }
    
    private var stepIndicator: some View {
        Group {
            if step == .addKeyboard {
                Text("STEP 1")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            } else if step == .showKeyboard {
                Text("STEP 2")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var instructionTexts: some View {
        VStack(spacing: 8) {
            Text(titleForStep())
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(instructionForStep())
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)
        }
    }
    
    private var textInputField: some View {
        TextField("", text: $testInput, prompt: Text("Click here to show keyboard"))
            .focused($isTextFieldFocused)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .onTapGesture(perform: handleTextFieldTap)
    }
    
    private var bottomButtonsSection: some View {
        VStack(spacing: 12) {
            if step == .addKeyboard {
                openSettingsButton
            } else if step == .complete {
                completeButton
            }

            if step == .showKeyboard {
                backToInstructionsButton
            }
        }
        .padding(.bottom)
    }
    
    private var openSettingsButton: some View {
        Button("Open Keyboard Settings") {
            openKeyboardSettings()
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private var completeButton: some View {
        Button("Complete") {
            isSetup = true
            dismiss()
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private var backToInstructionsButton: some View {
        Button("Having trouble? Close and reopen settings or go back to instructions") {
            step = .addKeyboard
        }
        .font(.footnote)
        .foregroundColor(.gray)
    }
    
    // MARK: - Helper Methods
    
    func titleForStep() -> String {
        switch step {
        case .addKeyboard: return "Add Your Keyboard"
        case .showKeyboard: return "Switch to Paleo Hebrew"
        case .complete: return "Test Your Keyboard"
        }
    }

    func instructionForStep() -> String {
        switch step {
        case .addKeyboard:
            return "To enable your Paleo Hebrew Keyboard, open your device settings, go to General > Keyboard > Keyboards > Add New Keyboard, and select Paleo Pro."
        case .showKeyboard:
            return "Click the text box below and switch to the Paleo Hebrew keyboard using the globe icon."
        case .complete:
            return "You're using the Paleo Hebrew keyboard. Type below to try it out, then tap Complete."
        }
    }
    
    private func handleTextFieldTap() {
      
                print("Input mode is not yet available")
            
        
    }


    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            step = .showKeyboard
        }
    }
    
    private func handleOnAppear() {
        let defaults = UserDefaults(suiteName: "group.com.d7mtg.paleopro")
        if defaults?.bool(forKey: "keyboardHasLaunched") == true {
            step = .showKeyboard
        }
    }
    
    private func handleInputChange(_ input: String) {
        if input.count > 0 {
            step = .complete
        }
    }
}

#Preview {
    SettingsView()
}
