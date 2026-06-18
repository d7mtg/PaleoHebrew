import Foundation

/// One letter of the alphabet, in its three representations.
/// `paleo` is the Paleo-Hebrew (Phoenician-block) glyph, `modern` the square
/// Hebrew letter, `name` the transliterated name.
struct PaleoLetter: Identifiable, Hashable, Sendable {
    let paleo: String
    let modern: String
    let name: String
    /// Standard gematria (numeric) value — a small bonus used for flourishes.
    let value: Int

    var id: String { name }
}

enum Alphabet {
    /// The 22 letters, in alphabetical order (Aleph … Tav).
    static let letters: [PaleoLetter] = [
        PaleoLetter(paleo: "𐤀", modern: "א", name: "Aleph", value: 1),
        PaleoLetter(paleo: "𐤁", modern: "ב", name: "Bet", value: 2),
        PaleoLetter(paleo: "𐤂", modern: "ג", name: "Gimel", value: 3),
        PaleoLetter(paleo: "𐤃", modern: "ד", name: "Dalet", value: 4),
        PaleoLetter(paleo: "𐤄", modern: "ה", name: "He", value: 5),
        PaleoLetter(paleo: "𐤅", modern: "ו", name: "Vav", value: 6),
        PaleoLetter(paleo: "𐤆", modern: "ז", name: "Zayin", value: 7),
        PaleoLetter(paleo: "𐤇", modern: "ח", name: "Chet", value: 8),
        PaleoLetter(paleo: "𐤈", modern: "ט", name: "Tet", value: 9),
        PaleoLetter(paleo: "𐤉", modern: "י", name: "Yod", value: 10),
        PaleoLetter(paleo: "𐤊", modern: "כ", name: "Kaf", value: 20),
        PaleoLetter(paleo: "𐤋", modern: "ל", name: "Lamed", value: 30),
        PaleoLetter(paleo: "𐤌", modern: "מ", name: "Mem", value: 40),
        PaleoLetter(paleo: "𐤍", modern: "נ", name: "Nun", value: 50),
        PaleoLetter(paleo: "𐤎", modern: "ס", name: "Samekh", value: 60),
        PaleoLetter(paleo: "𐤏", modern: "ע", name: "Ayin", value: 70),
        PaleoLetter(paleo: "𐤐", modern: "פ", name: "Pe", value: 80),
        PaleoLetter(paleo: "𐤑", modern: "צ", name: "Tsadi", value: 90),
        PaleoLetter(paleo: "𐤒", modern: "ק", name: "Qof", value: 100),
        PaleoLetter(paleo: "𐤓", modern: "ר", name: "Resh", value: 200),
        PaleoLetter(paleo: "𐤔", modern: "ש", name: "Shin", value: 300),
        PaleoLetter(paleo: "𐤕", modern: "ת", name: "Tav", value: 400),
    ]

    /// A deterministic "letter of the day" (cycles through the 22 by day of
    /// year) for widgets and the Home-Screen quick action.
    static var letterOfTheDay: PaleoLetter {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return letters[(day - 1) % letters.count]
    }

    // MARK: Lookup tables

    /// Modern square Hebrew → Paleo glyph.
    static let modernToPaleo: [String: String] = Dictionary(
        uniqueKeysWithValues: letters.map { ($0.modern, $0.paleo) }
    )

    /// Paleo glyph → modern square Hebrew.
    static let paleoToModern: [String: String] = Dictionary(
        uniqueKeysWithValues: letters.map { ($0.paleo, $0.modern) }
    )

    /// Final (sofit) forms → their regular medial form.
    static let finalToRegular: [Character: Character] = [
        "ך": "כ", "ם": "מ", "ן": "נ", "ף": "פ", "ץ": "צ",
    ]

    /// Regular form → final (sofit) form, for letters that have one.
    static let regularToFinal: [Character: Character] = [
        "כ": "ך", "מ": "ם", "נ": "ן", "פ": "ף", "צ": "ץ",
    ]

    // MARK: Unicode ranges

    /// Paleo-Hebrew lives in the Phoenician block U+10900–U+1091F.
    static func isPaleoScalar(_ s: Unicode.Scalar) -> Bool {
        (0x10900...0x1091F).contains(Int(s.value))
    }

    /// Square-Hebrew letters occupy U+05D0–U+05EA.
    static func isHebrewLetterScalar(_ s: Unicode.Scalar) -> Bool {
        (0x05D0...0x05EA).contains(Int(s.value))
    }
}
