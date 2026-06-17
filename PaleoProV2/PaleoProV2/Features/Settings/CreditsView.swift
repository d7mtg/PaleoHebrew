import SwiftUI

/// Attribution for the borrowed work in Paleo Pro: the ancient-script fonts and
/// the artifact photographs. Kept short and factual.
struct CreditsView: View {
    var body: some View {
        List {
            Section("Fonts") {
                creditRow(
                    title: "Ancient Semitic Scripts",
                    line: "Yoram Gnat (late), Culmus Project. GPL v2 with font exception.",
                    url: "https://culmus.sourceforge.io/ancient/index.html"
                )
                creditRow(
                    title: "Font pack",
                    line: "Curated by Aharon N. Varady, the Open Siddur Project.",
                    url: "https://opensiddur.org/help/fonts/"
                )
            }

            Section("Artifact photographs") {
                creditRow(title: "Siloam Inscription",
                          line: "Photo: Yael Y. CC BY-SA 3.0.",
                          url: "https://commons.wikimedia.org/wiki/File:IMJ_view_20130115_202733.jpg")
                creditRow(title: "Tel Dan Stele",
                          line: "Photo: Oren Rozen. CC BY-SA 4.0.",
                          url: "https://commons.wikimedia.org/wiki/File:JRSLM_300116_Tel_Dan_Stele_01.jpg")
                creditRow(title: "Half shekel",
                          line: "Photo: Classical Numismatic Group. CC BY-SA 3.0.",
                          url: "https://www.cngcoins.com")
            }

            Section {
                Link(destination: URL(string: "https://d7mtg.com")!) {
                    HStack {
                        Text("Design & development").foregroundStyle(.primary)
                        Spacer()
                        Text("D7mtg").foregroundStyle(.secondary)
                        Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Made by")
            } footer: {
                Text("Made with care in New York.")
            }
        }
        .navigationTitle("Credits")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func creditRow(title: String, line: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(line)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let link = URL(string: url) {
                Link("Source", destination: link)
                    .font(.caption.weight(.medium))
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { CreditsView() }
}
