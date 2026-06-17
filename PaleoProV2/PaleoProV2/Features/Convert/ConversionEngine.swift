import Foundation

/// Pure text conversion between modern square Hebrew and Paleo-Hebrew, with the
/// options a real epigraphy/study tool needs (niqqud, final forms, inscription
/// cleanup) — inspired by the Aleph transformation engine.
enum ConversionEngine {
    struct Options: Equatable {
        // Modern → Paleo
        /// Strip vowel points (niqqud) before converting — Paleo has no vowels.
        var stripNiqqud = true
        /// Join words with the inscriptional word-divider "·" instead of a space.
        var spacesAsDots = false
        // Paleo → Modern
        /// Rewrite each word's last letter as its final (sofit) form.
        var autoFinal = true
        /// Strip epigraphic marks: line numbers, [brackets], dashes, stray dots.
        var cleanInscription = false
    }

    static func convert(_ text: String, modernToPaleo: Bool, options: Options) -> String {
        modernToPaleo
            ? modernToPaleoText(text, options: options)
            : paleoToModernText(text, options: options)
    }

    // MARK: Niqqud (Hebrew points, U+0591–U+05C7)

    static func isNiqqud(_ scalar: Unicode.Scalar) -> Bool {
        (0x0591...0x05C7).contains(Int(scalar.value))
    }

    static func stripNiqqud(_ text: String) -> String {
        String(text.unicodeScalars.filter { !isNiqqud($0) })
    }

    // MARK: Modern → Paleo

    private static func modernToPaleoText(_ text: String, options: Options) -> String {
        var source = text
        if options.stripNiqqud { source = stripNiqqud(source) }

        let separator = options.spacesAsDots ? "·" : " "
        let words = source.split(separator: " ", omittingEmptySubsequences: false)
        let converted = words.map { word -> String in
            String(word).map { char -> String in
                let base = Alphabet.finalToRegular[char] ?? char
                return Alphabet.modernToPaleo[String(base)] ?? String(char)
            }.joined()
        }
        return converted.joined(separator: separator)
    }

    // MARK: Paleo → Modern

    /// Every word-divider we treat as a space when reading Paleo: the middle
    /// dot and bullet, the Phoenician word/number separators (U+1091F/U+1091E,
    /// used in our own Learning Center samples), the vertical bar, and the
    /// plain period.
    private static let wordDividers = ["·", "•", "\u{1091F}", "\u{1091E}", "|", "."]

    private static func paleoToModernText(_ text: String, options: Options) -> String {
        var source = text
        if options.cleanInscription { source = cleanInscription(source) }

        for token in wordDividers {
            source = source.replacingOccurrences(of: token, with: " ")
        }
        let words = source
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .map(String.init)

        let converted = words.map { word -> String in
            var letters = word.map { char -> Character in
                if let modern = Alphabet.paleoToModern[String(char)] {
                    return Character(modern)
                }
                return char
            }
            if options.autoFinal, let last = letters.last,
               let final = Alphabet.regularToFinal[last] {
                letters[letters.count - 1] = final
            }
            return String(letters)
        }
        return converted.joined(separator: " ")
    }

    /// Remove epigraphic transcription marks so a pasted inscription converts cleanly.
    private static func cleanInscription(_ text: String) -> String {
        var result = text
        // Leading line numbers like "2." or "13."
        result = result.replacingOccurrences(of: #"(?m)^\s*\d+\.\s*"#, with: "", options: .regularExpression)
        // Damaged/missing-text markers, dashes, and stray slashes
        for token in ["[", "]", "(", ")", "---", "--", "-", "\\", "/"] {
            result = result.replacingOccurrences(of: token, with: "")
        }
        // Collapse runs of whitespace
        result = result.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
