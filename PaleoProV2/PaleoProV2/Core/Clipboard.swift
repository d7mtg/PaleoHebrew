import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// One copy/paste call site for every platform. UIKit drives iOS, iPadOS, and
/// Mac Catalyst; AppKit handles native macOS; watchOS has no clipboard, so the
/// methods are no-ops there (and `hasString` is false).
enum Clipboard {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    static func paste() -> String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }

    static var hasString: Bool {
        #if canImport(UIKit)
        return UIPasteboard.general.hasStrings
        #elseif canImport(AppKit)
        return (NSPasteboard.general.string(forType: .string) ?? "").isEmpty == false
        #else
        return false
        #endif
    }
}
