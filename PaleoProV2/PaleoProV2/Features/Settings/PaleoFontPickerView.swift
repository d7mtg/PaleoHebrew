import SwiftUI

/// Lets the user pick the Paleo letterform used everywhere in the app (Learn,
/// the quiz, letter detail). Only the true 22-letter Paleo scripts are offered;
/// the other writing systems live on the per-letter evolution page instead.
struct PaleoFontPickerView: View {
    @AppStorage(PaleoFontPreference.key, store: PaleoFontPreference.store) private var fontID = ""

    private let sampleModern = "אבג"      // first three letters (Culmus fonts are Hebrew-keyed)
    private let samplePaleo = "𐤀𐤁𐤂"        // the same in Unicode Paleo

    var body: some View {
        Form {
            Section {
                Button { choose("") } label: { defaultRow }.tint(.primary)
            }
            Section {
                ForEach(ScribalFonts.globalEligible) { font in
                    Button { choose(font.id) } label: { fontRow(font) }.tint(.primary)
                }
            } header: {
                Text("Ancient inscriptions")
            } footer: {
                Text("Ancient script fonts by the late Yoram Gnat (Culmus Project), based on real inscriptions. See Credits in Settings.")
            }
        }
        .navigationTitle("Letterform")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var defaultRow: some View {
        rowLayout(
            sample: Text(samplePaleo).font(.system(size: 30)),
            title: "Default",
            subtitle: "Unicode Paleo-Hebrew",
            selected: fontID.isEmpty
        )
    }

    private func fontRow(_ font: ScribalFont) -> some View {
        rowLayout(
            sample: Text(sampleModern).font(.custom(font.postScriptName, size: 30)),
            title: font.displayName,
            subtitle: font.era,
            selected: fontID == font.id
        )
    }

    private func rowLayout(sample: Text, title: String, subtitle: String, selected: Bool) -> some View {
        HStack(spacing: Spacing.lg) {
            sample
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 96, height: 44, alignment: .leading)
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark").font(.headline).foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }

    private func choose(_ id: String) {
        fontID = id
        Haptics.select()
    }
}

#Preview {
    NavigationStack { PaleoFontPickerView() }
}
