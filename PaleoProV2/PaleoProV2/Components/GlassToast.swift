import SwiftUI

/// A transient confirmation shown as a floating glass capsule. `content` is the
/// actual string copied to the pasteboard — the toast reads "Copied <content>".
struct ToastState: Equatable, Identifiable {
    let id = UUID()
    var content: String
    var symbol: String = "checkmark"
}

private struct ToastView: View {
    let toast: ToastState

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.tint)
            (
                Text("Copied ").foregroundStyle(.secondary)
                + Text(toast.content).fontWeight(.bold)
            )
            .font(.subheadline)
            .lineLimit(1)
            .truncationMode(.tail)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .glassEffect(.regular, in: .capsule)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: ToastState?
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast {
                    ToastView(toast: toast)
                        .padding(.bottom, 28)
                        .transition(.materialize)
                }
            }
            // Every new toast.id fully cancels the in-flight dismiss and
            // starts a fresh 1.5 s timer, so rapid taps reliably keep it up.
            .onChange(of: toast?.id) { _, newID in
                dismissTask?.cancel()
                guard newID != nil else { return }
                dismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    if !Task.isCancelled {
                        withAnimation(.smooth(duration: 0.3)) { toast = nil }
                    }
                }
            }
    }
}

extension View {
    /// Floating glass toast that auto-dismisses 1.5 s after the latest update.
    /// Rapid updates swap content in place and reset the timer; the slide-in
    /// animation only fires when the toast first appears.
    func toast(_ toast: Binding<ToastState?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
