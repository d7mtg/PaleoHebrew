import SwiftUI

struct CheatSheetView: View {
    @State private var isGridView = true
    @State private var showToast = false
    @State private var copiedCharacter = ""
    @State private var copiedDescription = "COPIED"
    @State private var tappedItemId: String? = nil
    @State private var toastWorkItem: DispatchWorkItem?
    
    // Namespace for matched geometry effect
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Paleo Pro")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    
                    // Custom toggle instead of Picker
                    HStack(spacing: 0) {
                        Button(action: {
                            if !isGridView {
                                // Switch to grid view with multiple haptic clicks
                                playGridHapticFeedback()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isGridView = true
                                }
                            }
                        }) {
                            Image(systemName: "square.grid.3x2")
                                .padding(8)
                                .background(isGridView ? Color.accentColor : Color.clear)
                                .foregroundColor(isGridView ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        
                        Button(action: {
                            if isGridView {
                                // Switch to list view with smooth haptic feedback
                                playListHapticFeedback()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isGridView = false
                                }
                            }
                        }) {
                            Image(systemName: "list.bullet")
                                .padding(8)
                                .background(!isGridView ? Color.accentColor : Color.clear)
                                .foregroundColor(!isGridView ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding([.top, .horizontal])

                // Content with matched geometry transition
                ScrollView {
                    if isGridView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(paleoLetters, id: \.name) { letter in
                                letterCell(letter, isGrid: true)
                                    .matchedGeometryEffect(id: letter.name, in: animation)
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                        .padding()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(paleoLetters, id: \.name) { letter in
                                letterCell(letter, isGrid: false)
                                    .matchedGeometryEffect(id: letter.name, in: animation)
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                }
            }
            
            // Toast notification
            if showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Text(copiedCharacter)
                            .font(.title2)
                            .foregroundColor(Color.primary)
                            .lineLimit(1)
                        Spacer()
                        Text(copiedDescription)
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
                    .padding(.horizontal, 20)
                    .frame(minWidth: 200, maxWidth: UIScreen.main.bounds.width * 0.9)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(1)
                .animation(.spring(response: 0.3), value: showToast)
            }
        }
    }
    
    // Grid haptic feedback - multiple distinct clicks
    private func playGridHapticFeedback() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()
        
        // First click
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
        
        // Multiple smaller clicks in sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.2)
        }
    }
    
    // List haptic feedback - smoother, more flowing
    private func playListHapticFeedback() {
        // Start with a soft impact
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
        
        // Follow with a selection feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        
        // End with a medium impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        }
    }
    
    // Unified cell view that adapts to grid or list layout
    private func letterCell(_ letter: PaleoLetter, isGrid: Bool) -> some View {
        Group {
            if isGrid {
                VStack {
                    Text(letter.modern)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(letter.paleo)
                        .font(.largeTitle)
                    Text(letter.name)
                        .textCase(.uppercase)
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding()
            } else {
                HStack {
                    Text(letter.paleo)
                        .font(.largeTitle)
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    Text(letter.name)
                        .textCase(.uppercase)
                        .font(.caption2.monospaced())
                    Spacer()
                    Text(letter.modern)
                        .font(.largeTitle.weight(.semibold))
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(tappedItemId == letter.name ?
                      Color(Color.accentColor) : Color(.systemGray6))
        )
        .onTapGesture {
            copyToClipboard(letter.paleo, id: letter.name)
        }
        .contextMenu {
            Button {
                copyToClipboard(letter.paleo, id: letter.name, description: "PALEO COPIED")
            } label: {
                Label("Copy Paleo \"\(letter.paleo)\"", systemImage: "doc.on.doc")
            }
            
            Button {
                copyToClipboard(letter.modern, id: letter.name, description: "MODERN COPIED")
            } label: {
                Label("Copy Modern \"\(letter.modern)\"", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Menu("Advanced") {
                Button {
                    let unicodeValue = getUnicodeValue(letter.paleo)
                    copyToClipboard(unicodeValue, id: letter.name, description: "UNICODE COPIED")
                } label: {
                    Text("Copy Unicode (\(getUnicodeValue(letter.paleo, formatted: true)))")
                }
                
                Button {
                    if let htmlEntity = getHTMLEntity(letter.paleo) {
                        copyToClipboard(htmlEntity, id: letter.name, description: "HTML COPIED")
                    }
                } label: {
                    if let htmlEntity = getHTMLEntity(letter.paleo) {
                        Text("Copy HTML Entity (\(htmlEntity))")
                    } else {
                        Text("Copy HTML Entity")
                    }
                }
            }
        }


    }
    
    private func copyToClipboard(_ text: String, id: String, description: String = "COPIED") {
        toastWorkItem?.cancel()
        
        UIPasteboard.general.string = text
        
        tappedItemId = id
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        copiedCharacter = text
        copiedDescription = description
        withAnimation {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation {
                tappedItemId = nil
            }
        }
        
        let workItem = DispatchWorkItem {
            withAnimation {
                showToast = false
            }
        }
        
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
    
    // Helper function to get Unicode value of a character
    private func getUnicodeValue(_ character: String, formatted: Bool = false) -> String {
        guard let firstScalar = character.unicodeScalars.first else { return "" }
        let unicodeValue = String(format: "U+%04X", firstScalar.value)
        return formatted ? unicodeValue : unicodeValue
    }
    
    // Helper function to get HTML entity of a character
    private func getHTMLEntity(_ character: String) -> String? {
        guard let firstScalar = character.unicodeScalars.first else { return nil }
        return "&#x\(String(format: "%X", firstScalar.value));"
    }
}

#Preview {
    CheatSheetView()
}
