import AppKit
import SwiftUI

/// SwiftUI ビューを AppKit の `NSWindow` に載せて表示する。
/// `LSUIElement` アプリでも確実に前面に出せるよう、SwiftUI の `Window` シーンではなく自前で管理する。
@MainActor
final class WindowPresenter {
    private var windows: [String: NSWindow] = [:]
    private var closeObservers: [String: NSObjectProtocol] = [:]

    /// `id` のウィンドウを表示する。既に開いていれば前面に出すだけ。
    func show<Content: View>(
        id: String,
        title: String,
        resizable: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let existing = windows[id] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: content())
        let window = NSWindow(contentViewController: hosting)
        window.title = title
        var mask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        if resizable { mask.insert(.resizable) }
        window.styleMask = mask
        window.isReleasedWhenClosed = false
        window.center()

        windows[id] = window
        closeObservers[id] = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.forget(id: id) }
        }
        window.makeKeyAndOrderFront(nil)
    }

    func close(id: String) {
        windows[id]?.close()
    }

    func isOpen(id: String) -> Bool {
        windows[id] != nil
    }

    private func forget(id: String) {
        if let token = closeObservers.removeValue(forKey: id) {
            NotificationCenter.default.removeObserver(token)
        }
        windows[id] = nil
    }
}
