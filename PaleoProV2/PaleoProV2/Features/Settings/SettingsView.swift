import SwiftUI

struct SettingsView: View {
    @State private var showDebug = false
    @State private var keyboardSheet = false
    @State private var keyboardReady = KeyboardStatus.isSetUp
    @AppStorage(PaleoFontPreference.key, store: PaleoFontPreference.store) private var paleoFontID = ""

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                if showDebug { debugSection }
                keyboardSection
                letterformSection
                aboutSection
                footerSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $keyboardSheet, onDismiss: {
                withAnimation(Motion.smooth) { keyboardReady = KeyboardStatus.isSetUp }
            }) {
                KeyboardSetupView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
            }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        Section {
            VStack(spacing: Spacing.md) {
                FakeAppIcon()
                    .frame(width: 92, height: 92)

                VStack(spacing: 2) {
                    Text("Paleo Pro")
                        .font(.title2.weight(.bold))
                    Text("Learn the ancient Hebrew alphabet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: Keyboard

    private var keyboardSection: some View {
        Section("Keyboard") {
            Button { keyboardSheet = true } label: {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.tint)
                        .frame(width: 26)
                    Text(keyboardReady ? "Paleo Hebrew keyboard is set up" : "Set Up Paleo Hebrew Keyboard")
                    Spacer()
                    if keyboardReady {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce, value: keyboardReady)
                    } else {
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
                    }
                }
            }
            .tint(.primary)
        }
    }

    // MARK: Letterform

    private var letterformSection: some View {
        Section("Letterform") {
            NavigationLink {
                PaleoFontPickerView()
            } label: {
                HStack {
                    Label("Paleo Letterform", systemImage: "textformat")
                    Spacer()
                    Text(ScribalFonts.font(id: paleoFontID)?.displayName ?? "Default")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .tint(.primary)
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            NavigationLink {
                AboutPaleoHebrewView()
            } label: {
                Label("Learning Center", systemImage: "books.vertical")
            }
            Link(destination: URL(string: "https://aleph.d7mtg.com")!) {
                aboutRow("More tools like this", "square.grid.2x2")
            }
            Link(destination: URL(string: "https://d7mtg.com/privacy")!) {
                aboutRow("Privacy Policy", "hand.raised")
            }
            Link(destination: URL(string: "https://apps.apple.com/app/id6743683727?action=write-review")!) {
                aboutRow("Rate Paleo Pro", "star")
            }
            NavigationLink {
                CreditsView()
            } label: {
                Label("Credits", systemImage: "hands.clap")
            }
        }
    }

    private func aboutRow(_ title: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(.tertiary)
        }
        .tint(.primary)
    }

    // MARK: Debug

    private var debugSection: some View {
        Section("Debug") {
            #if canImport(UIKit)
            LabeledContent("iOS", value: UIDevice.current.systemVersion)
            LabeledContent("Model", value: UIDevice.current.model)
            #else
            LabeledContent("OS", value: ProcessInfo.processInfo.operatingSystemVersionString)
            LabeledContent("Host", value: Host.current().localizedName ?? "Mac")
            #endif
            LabeledContent("App Group", value: Shared.appGroup)
            LabeledContent("Keyboard", value: keyboardReady ? "Set up" : "Not set up")
            Button("Hide Debug Info") {
                withAnimation(Motion.smooth) { showDebug = false }
            }
        }
    }

    // MARK: Footer

    private var footerSection: some View {
        Section {
            EmptyView()
        } footer: {
            VStack(spacing: 4) {
                Link("Designed by D7mtg", destination: URL(string: "https://d7mtg.com")!)
                    .font(.footnote.weight(.medium))
                Text("Version 2.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .onLongPressGesture(minimumDuration: 1.2) {
                        withAnimation(Motion.smooth) { showDebug = true }
                        Haptics.success()
                    }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.sm)
        }
    }
}

#Preview {
    SettingsView()
}
