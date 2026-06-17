import StoreKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Asks for an App Store review at genuinely positive moments.
///
/// Fixes the V1 quirk where one shared `copyCount` was bumped by *every* quiz
/// question advance, so gameplay alone could trigger the prompt. Here, only
/// real "I got value" moments count: copying a glyph, and finishing a quiz well.
@MainActor
enum ReviewCoordinator {
    private static let copyCountKey = "meaningfulCopyCount"
    private static let askedKey = "lastReviewAskCount"
    private static let copyMilestones: Set<Int> = [12, 45, 150]

    static func recordCopy() {
        let d = UserDefaults.standard
        let n = d.integer(forKey: copyCountKey) + 1
        d.set(n, forKey: copyCountKey)
        if copyMilestones.contains(n) { request() }
    }

    static func recordQuizFinished(percent: Double) {
        guard percent >= 0.8 else { return }
        let d = UserDefaults.standard
        let copies = d.integer(forKey: copyCountKey)
        // Only ask off the back of a quiz if we haven't recently asked via copies.
        if copies >= 6 && d.integer(forKey: askedKey) != copies {
            d.set(copies, forKey: askedKey)
            request()
        }
    }

    private static func request() {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        AppStore.requestReview(in: scene)
        #else
        // macOS: SKStoreReviewController.requestReview() is the Mac equivalent;
        // it shows a native "Enjoying Paleo Pro?" prompt on the active window.
        SKStoreReviewController.requestReview()
        #endif
    }
}
