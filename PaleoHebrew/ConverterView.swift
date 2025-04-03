import SwiftUI

struct ConverterView: View {
    
    @State private var modernText = ""
    @State private var paleoText = ""
    @State private var isModernTopaleo = true
    @State private var isInputFocused = false // Changed from @FocusState to @State
    @State private var showToast = false
    @State private var copiedText = ""
    @State private var toastWorkItem: DispatchWorkItem?
    @State private var flipState = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Settings
    @State private var replaceSpacesWithDots = false
    @State private var convertDotsToSpaces = true
    @State private var useAutoFinalLetters = true
    
    // Paleo Hebrew to Modern Hebrew mapping
    private let paleoLetters: [(paleo: String, modern: String)] = [
        ("𐤀", "א"), // Alef
        ("𐤁", "ב"), // Bet
        ("𐤂", "ג"), // Gimel
        ("𐤃", "ד"), // Dalet
        ("𐤄", "ה"), // He
        ("𐤅", "ו"), // Vav
        ("𐤆", "ז"), // Zayin
        ("𐤇", "ח"), // Het
        ("𐤈", "ט"), // Tet
        ("𐤉", "י"), // Yod
        ("𐤊", "כ"), // Kaf
        ("𐤋", "ל"), // Lamed
        ("𐤌", "מ"), // Mem
        ("𐤍", "נ"), // Nun
        ("𐤎", "ס"), // Samekh
        ("𐤏", "ע"), // Ayin
        ("𐤐", "פ"), // Pe
        ("𐤑", "צ"), // Tsadi
        ("𐤒", "ק"), // Qof
        ("𐤓", "ר"), // Resh
        ("𐤔", "ש"), // Shin
        ("𐤕", "ת")  // Tav
    ]
    
    var body: some View {
        ZStack {
            MainContentView(
                modernText: $modernText,
                paleoText: $paleoText,
                isModernTopaleo: $isModernTopaleo,
                isInputFocused: $isInputFocused,
                flipState: $flipState,
                replaceSpacesWithDots: $replaceSpacesWithDots,
                convertDotsToSpaces: $convertDotsToSpaces,
                useAutoFinalLetters: $useAutoFinalLetters,
                copiedText: $copiedText,  // Add this line
                convertModernToPaleo: convertModernToPaleo,
                convertPaleoToModern: convertPaleoToModern,
                showCopiedToast: showCopiedToast
            )
            
            // Toast notification
            SourceToastView(showToast: $showToast, copiedText: copiedText)
        }
    }
    
    private func showCopiedToast() {
        toastWorkItem?.cancel()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            showToast = true
        }
        
        let workItem = DispatchWorkItem {
            withAnimation {
                showToast = false
            }
        }
        
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
    
    private func convertPaleoToModern(_ text: String) -> String {
        if text.isEmpty { return "" }

        var result = ""

        // Normalize dots (., ·, •) with optional surrounding spaces to a single space
        let dotPattern = #"(\s*[·•.]\s*)"#  // any dot-like character
        let regex = try? NSRegularExpression(pattern: dotPattern, options: [])
        let normalized = regex?.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: text.utf16.count), withTemplate: " ") ?? text

        // Collapse multiple spaces but keep line breaks
        let cleaned = normalized
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")

        let words = cleaned.split(separator: " ")

        for (wordIndex, word) in words.enumerated() {
            var currentWord = ""

            for (charIndex, char) in word.enumerated() {
                if let letter = paleoLetters.first(where: { $0.paleo == String(char) }) {
                    if useAutoFinalLetters && charIndex == word.count - 1 {
                        let finalChar = getModernFinalLetter(letter.modern.first ?? Character(""))
                        currentWord += String(finalChar)
                    } else {
                        currentWord += letter.modern
                    }
                } else {
                    currentWord += String(char)
                }
            }

            result += currentWord

            if wordIndex < words.count - 1 {
                result += " "
            }
        }

        return result
    }
    
    private func convertModernToPaleo(_ text: String) -> String {
        if text.isEmpty { return "" }
        
        var result = ""
        let words = text.split(separator: " ")
        
        for (wordIndex, word) in words.enumerated() {
            var currentWord = ""
            
            for char in word {
                // First check for the exact character
                if let letter = paleoLetters.first(where: { $0.modern == String(char) }) {
                    currentWord += letter.paleo
                } else {
                    // If not found, check if it's a final letter and map to the regular form
                    let regularChar = mapFinalLetterToRegular(char)
                    if let letter = paleoLetters.first(where: { $0.modern == String(regularChar) }) {
                        currentWord += letter.paleo
                    } else {
                        // Keep non-Modern Hebrew characters as is
                        currentWord += String(char)
                    }
                }
            }
            
            result += currentWord
            
            // Add appropriate separator between words
            if wordIndex < words.count - 1 {
                result += replaceSpacesWithDots ? "·" : " "
            }
        }
        
        return result
    }
    
    private func mapFinalLetterToRegular(_ char: Character) -> Character {
        switch char {
        case "ך": return "כ" // Final Kaf to regular Kaf
        case "ם": return "מ" // Final Mem to regular Mem
        case "ן": return "נ" // Final Nun to regular Nun
        case "ף": return "פ" // Final Pe to regular Pe
        case "ץ": return "צ" // Final Tsadi to regular Tsadi
        default: return char
        }
    }
    
    private func getModernFinalLetter(_ char: Character) -> Character {
        switch char {
        case "כ": return "ך" // Regular Kaf to Final Kaf
        case "מ": return "ם" // Regular Mem to Final Mem
        case "נ": return "ן" // Regular Nun to Final Nun
        case "פ": return "ף" // Regular Pe to Final Pe
        case "צ": return "ץ" // Regular Tsadi to Final Tsadi
        default: return char
        }
    }
}

// Main content view that contains the navigation view and main container
struct MainContentView: View {
    @Binding var modernText: String
    @Binding var paleoText: String
    @Binding var isModernTopaleo: Bool
    @Binding var isInputFocused: Bool
    @Binding var flipState: Bool
    @Binding var replaceSpacesWithDots: Bool
    @Binding var convertDotsToSpaces: Bool
    @Binding var useAutoFinalLetters: Bool
    @Binding var copiedText: String  // Add this line
    var convertModernToPaleo: (String) -> String
    var convertPaleoToModern: (String) -> String
    var showCopiedToast: () -> Void
    

    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main container
                VStack(spacing: 0) {
                    // Input section
                    InputSection(
                        text: Binding(
                            get: { isModernTopaleo ? modernText : paleoText },
                            set: { newValue in
                                if isModernTopaleo {
                                    modernText = newValue
                                    paleoText = convertModernToPaleo(newValue)
                                } else {
                                    paleoText = newValue
                                    modernText = convertPaleoToModern(newValue)
                                }
                            }
                        ),
                        isModernTopaleo: isModernTopaleo,
                        isInputFocused: $isInputFocused
                    )
                    
                    // Divider with swap button
                    DividerWithSwapButton(
                        isModernTopaleo: $isModernTopaleo,
                        flipState: $flipState,
                        modernText: $modernText,
                        paleoText: $paleoText,
                        isInputFocused: $isInputFocused,
                        convertModernToPaleo: convertModernToPaleo,
                        convertPaleoToModern: convertPaleoToModern
                    )
                    
                    OutputSection(
                        outputText: isModernTopaleo ? paleoText : modernText,
                        placeholderText: isModernTopaleo ? "𐤊𐤕𐤁·𐤏𐤁𐤓𐤉·𐤉𐤅𐤐𐤉·𐤊𐤀𐤍" : "כתב אשורית יופיע כאן",
                        isModernTopaleo: isModernTopaleo,
                        replaceSpacesWithDots: $replaceSpacesWithDots,
                        convertDotsToSpaces: $convertDotsToSpaces,
                        useAutoFinalLetters: $useAutoFinalLetters,
                        onCopy: {
                            let textToCopy = isModernTopaleo ? paleoText : modernText
                            UIPasteboard.general.string = textToCopy
                            copiedText = textToCopy // Ensure copiedText is updated here
                            showCopiedToast()
                        },
                        convertModernToPaleo: convertModernToPaleo,
                        convertPaleoToModern: convertPaleoToModern
                    )
                }
                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 1)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Converter")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                // Only show dismiss keyboard button when keyboard is visible
                if isInputFocused {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isInputFocused = false
                        }
                    }
                }
            }
        }
    }
}

// Input section view
struct InputSection: View {
    @Binding var text: String
    let isModernTopaleo: Bool
    @Binding var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Placeholder text with adjusted alignment
                if text.isEmpty {
                    HStack {
                        Spacer()
                        Text(isModernTopaleo ? "הקלד כתב אשורית כאן" : "𐤄𐤒𐤋𐤃·𐤊𐤕𐤁·𐤏𐤁𐤓𐤉·𐤊𐤀𐤍")
                            .font(.title)
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 16)
                            .padding(.trailing, 50)
                            .padding(.leading, 16)  // Align with text input
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                
                // Text editor
                RTLTextEditor(
                    text: $text,
                    isFocused: $isInputFocused
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 0)
                .padding(.top, 8)
                
                // Controls
                InputControls(text: $text, isModernTopaleo: isModernTopaleo)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = true
            }
        }
    }
}

// Input control buttons
struct InputControls: View {
    @Binding var text: String
    let isModernTopaleo: Bool
    
    var body: some View {
        VStack {
            // Clear button at top
            HStack {
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 20))
                            .padding(12)
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Paste button at bottom
            HStack {
                if UIPasteboard.general.hasStrings {
                    Button(action: {
                        if let pasteText = UIPasteboard.general.string {
                            text = pasteText
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 18))
                            .padding(6)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}

// Divider with swap button
struct DividerWithSwapButton: View {
    @Binding var isModernTopaleo: Bool
    @Binding var flipState: Bool
    @Binding var modernText: String
    @Binding var paleoText: String
    @Binding var isInputFocused: Bool
    var convertModernToPaleo: (String) -> String
    var convertPaleoToModern: (String) -> String
    
    var body: some View {
        ZStack {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button(action: {
                // Flip the icon
                withAnimation(.easeInOut(duration: 0.3)) {
                    flipState.toggle()
                }
                
                // Change state and trigger conversion
                isModernTopaleo.toggle()
                
                // Explicitly run conversion after flip
                if isModernTopaleo {
                    paleoText = convertModernToPaleo(modernText)
                } else {
                    modernText = convertPaleoToModern(paleoText)
                }
                
                isInputFocused = false
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .rotation3DEffect(
                        flipState ? .degrees(180) : .degrees(0),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .zIndex(1)
        }
    }
}

// Output section view
struct OutputSection: View {
    let outputText: String
    let placeholderText: String
    let isModernTopaleo: Bool
    @Binding var replaceSpacesWithDots: Bool
    @Binding var convertDotsToSpaces: Bool
    @Binding var useAutoFinalLetters: Bool
    var onCopy: () -> Void
    var convertModernToPaleo: (String) -> String
    var convertPaleoToModern: (String) -> String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Settings menu
            SettingsMenu(
                isModernTopaleo: isModernTopaleo,
                replaceSpacesWithDots: $replaceSpacesWithDots,
                convertDotsToSpaces: $convertDotsToSpaces,
                useAutoFinalLetters: $useAutoFinalLetters,
                convertModernToPaleo: convertModernToPaleo,
                convertPaleoToModern: convertPaleoToModern
            )
            
            // Output text area
            ZStack(alignment: .topTrailing) {
                // Placeholder with same alignment as the output text
                if outputText.isEmpty {
                    HStack {
                        Spacer()
                        Text(placeholderText)
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .opacity(0.4)
                            .padding(.top, 16)
                            .padding(.trailing, 50)
                            .padding(.leading, 16)  // Align with text input
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                
                // Actual output text
                if !outputText.isEmpty {
                    ScrollView {
                        Text(outputText)
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .multilineTextAlignment(.leading)
                            .environment(\.layoutDirection, .rightToLeft)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .textSelection(.enabled)
                        
                    }
                }
                
                // Copy button
                VStack {
                    Spacer()
                    
                    HStack {
                        if !outputText.isEmpty {
                            Button(action: onCopy) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 18))
                                    .padding(6)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// Settings menu
struct SettingsMenu: View {
    let isModernTopaleo: Bool
    @Binding var replaceSpacesWithDots: Bool
    @Binding var convertDotsToSpaces: Bool
    @Binding var useAutoFinalLetters: Bool
    var convertModernToPaleo: (String) -> String
    var convertPaleoToModern: (String) -> String
    var body: some View {
        HStack {
            Menu {
                if isModernTopaleo {
                    // Modern to Paleo settings
                    Toggle("Replace spaces with dots", isOn: $replaceSpacesWithDots)
                        .onChange(of: replaceSpacesWithDots) { _ in
                            if isModernTopaleo {
                                _ = convertModernToPaleo("")
                            }
                        }
                } else {
                    // Paleo to Modern settings
                    Toggle("Convert dots to spaces", isOn: $convertDotsToSpaces)
                        .onChange(of: convertDotsToSpaces) { _ in
                            if !isModernTopaleo {
                                _ = convertPaleoToModern("")
                            }
                        }
                    Toggle("Auto-detect final letters", isOn: $useAutoFinalLetters)
                        .onChange(of: useAutoFinalLetters) { _ in
                            if !isModernTopaleo {
                                _ = convertPaleoToModern("")
                            }
                        }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18))
                    .padding(6)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// Toast notification view
struct SourceToastView: View {
    @Binding var showToast: Bool
    let copiedText: String
    
    var body: some View {
        if showToast {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Text(copiedText)
                        .font(.title2)
                        .foregroundColor(Color.primary)
                        .lineLimit(1)
                    Spacer()
                    Text("COPIED")
                        .font(.caption.monospaced())
                        .fontWeight(.medium)
                        .foregroundColor(Color.primary.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .padding(.bottom, 20)
                .padding(.horizontal, 120)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(1)
            .animation(.spring(response: 0.3), value: showToast)
        }
    }
}

struct RTLTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .title1)
        textView.textAlignment = .right
        textView.textColor = colorScheme == .dark ? .white : .black
        textView.backgroundColor = .clear
        // Align text insets with placeholder
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 32, bottom: 8, right: 12)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.keyboardType = .default
        textView.returnKeyType = .default
        
        // Set RTL direction using semanticContentAttribute
        textView.semanticContentAttribute = .forceRightToLeft
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update text if it's different to prevent cursor reset
        if uiView.text != text {
            uiView.text = text
        }
        uiView.textColor = colorScheme == .dark ? .white : .black
        
        // Handle focus state but don't dismiss during typing
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RTLTextEditor
        
        init(_ parent: RTLTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            // Don't update isFocused here to prevent keyboard dismissal
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }
        
        // Prevent dismissal on return key - only dismiss on toolbar "Done" button
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Allow all text changes, including return key
            return true
        }
    }
}

#Preview {
    ConverterView()
}
