import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

/// Indexes the 22 letters in system Spotlight so searching "Aleph" (or the
/// glyph, or the modern letter) surfaces the app and deep-links into that
/// letter. The deep link is delivered as an `NSUserActivity` of type
/// `CSSearchableItemActionType`; RootView routes it through `AppNavigation`.
enum SpotlightIndex {
    static let domain = "letters"

    static func indexLetters() {
        let items = Alphabet.letters.map { letter -> CSSearchableItem in
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            // displayName is what Spotlight matches and shows most prominently.
            attrs.displayName = letter.name
            attrs.title = "\(letter.name)  \(letter.paleo)"
            attrs.contentDescription = "Paleo-Hebrew \(letter.paleo) · Modern \(letter.modern)"
            attrs.keywords = [letter.name, letter.modern, letter.paleo,
                              "paleo", "hebrew", "alphabet", "aleph bet", "letter"]
            let item = CSSearchableItem(uniqueIdentifier: letter.id,
                                        domainIdentifier: domain,
                                        attributeSet: attrs)
            item.expirationDate = .distantFuture // keep entries indexed indefinitely
            return item
        }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error { print("[Spotlight] indexing failed: \(error.localizedDescription)") }
        }
    }
}
