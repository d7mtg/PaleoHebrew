import UIKit
import SwiftUI
import CoreText
import UniformTypeIdentifiers

/// Share extension: takes text selected in any app and converts it to
/// Paleo-Hebrew, with a one-tap copy. Pure and self-contained (it reuses
/// ConversionEngine + Alphabet, and bundles the Siloam font to render Paleo).
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        loadSharedText { [weak self] text in
            self?.show(text: text)
        }
    }

    private func show(text: String) {
        let root = ShareConvertView(input: text) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
    }

    private func loadSharedText(completion: @escaping (String) -> Void) {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []
        let plain = UTType.plainText.identifier
        let any = UTType.text.identifier
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(plain) })
            ?? providers.first(where: { $0.hasItemConformingToTypeIdentifier(any) }) else {
            completion(""); return
        }
        let type = provider.hasItemConformingToTypeIdentifier(plain) ? plain : any
        provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
            let text = (item as? String) ?? (item as? URL)?.absoluteString ?? ""
            DispatchQueue.main.async { completion(text) }
        }
    }
}

// MARK: - UI

/// Register the bundled Siloam font once so the Paleo output renders.
private let siloamReady: Bool = {
    if let url = Bundle.main.url(forResource: "SILOAM", withExtension: "TTF") {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
    return true
}()

struct ShareConvertView: View {
    let input: String
    var onDone: () -> Void

    @State private var copied = false

    /// Shared text is treated as modern Hebrew converting to Paleo.
    private var output: String {
        ConversionEngine.convert(
            input, modernToPaleo: true,
            options: .init(stripNiqqud: true, spacesAsDots: false, autoFinal: false, cleanInscription: false)
        )
    }

    /// Siloam is keyed on modern Hebrew letters, so map the Paleo output back to
    /// modern and render it in that ancient hand. Copy still uses real Paleo.
    private var displayPaleo: String {
        _ = siloamReady
        return output.map { Alphabet.paleoToModern[String($0)] ?? String($0) }.joined()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    card("Your text") {
                        Text(input.isEmpty ? "No text was shared." : input)
                            .font(.title3)
                            .foregroundStyle(input.isEmpty ? .secondary : .primary)
                    }
                    Image(systemName: "arrow.down").foregroundStyle(.secondary)
                    card("Paleo-Hebrew") {
                        Text(displayPaleo)
                            .font(.custom("Hebrew-Paleo-Siloam", size: 40))
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                    if !output.isEmpty {
                        Button {
                            UIPasteboard.general.string = output
                            withAnimation { copied = true }
                        } label: {
                            Label(copied ? "Copied" : "Copy Paleo-Hebrew",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
            .navigationTitle("Convert to Paleo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
    }

    @ViewBuilder
    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            content().frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
    }
}
