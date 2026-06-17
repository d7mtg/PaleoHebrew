import SwiftUI
import WatchKit

/// Companion watch app: an Aleph-to-Tav letter browser with an About screen.
struct WatchRootView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(Alphabet.letters) { letter in
                    NavigationLink(value: WatchRoute.letter(letter)) {
                        HStack(spacing: 12) {
                            Text(letter.paleo)
                                .font(.system(size: 28))
                                .frame(width: 36, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(letter.name).font(.headline)
                                Text(letter.modern)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    NavigationLink(value: WatchRoute.about) {
                        Label("About Paleo Pro", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Paleo Pro")
            .navigationDestination(for: WatchRoute.self) { route in
                switch route {
                case .letter(let letter): LetterDetail(letter: letter)
                case .about: AboutView()
                }
            }
        }
    }
}

private enum WatchRoute: Hashable {
    case letter(PaleoLetter)
    case about
}

// MARK: - Letter detail

private struct LetterDetail: View {
    let letter: PaleoLetter
    @State private var crown: Double = 1

    var body: some View {
        VStack(spacing: 8) {
            Text(letter.paleo)
                .font(.system(size: 110))
                .foregroundStyle(.tint)
                .scaleEffect(0.6 + (crown / 2))
                .focusable()
                .digitalCrownRotation(
                    $crown,
                    from: 0, through: 1, by: 0.05,
                    sensitivity: .medium
                )
            Text(letter.name).font(.title3.weight(.semibold))
            Text(letter.modern).font(.title.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(letter.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { WKInterfaceDevice.current().play(.click) }
    }
}

// MARK: - About

private struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image("AppIconMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 52)
                    .foregroundStyle(.tint)
                    .padding(.top, 4)

                VStack(spacing: 2) {
                    Text("Paleo Pro")
                        .font(.headline)
                    Text("Version 2.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Learn the ancient Hebrew alphabet — 22 letters that have been in use for three thousand years and quietly fathered most of the world's writing systems.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 6) {
                    Text("𐤀𐤁𐤂𐤃𐤄𐤅")
                        .font(.system(size: 28))
                        .foregroundStyle(.tint)
                    Text("Aleph through He, in Paleo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)

                Text("For the full experience — quiz, converter, and a Paleo Hebrew keyboard — open Paleo Pro on iPhone or iPad.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                Text("Designed by D7mtg")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { WatchRootView() }
