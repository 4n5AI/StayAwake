import AppKit

/// 確認ダイアログ（AppKit の `NSAlert`）。
@MainActor
enum Dialogs {
    /// 「無期限」選択時の確認。ユーザーが承認した場合のみ true。
    static func confirmIndefinite() -> Bool {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "無期限で画面を維持しますか？"
        alert.informativeText =
            "「停止」を選ぶまで画面が消えなくなります。離席するときは必ず手動でロック（Ctrl+Cmd+Q）するか、メニューの「停止」を選んでください。\n\n"
            + "画面ロック・バッテリー低下（15%未満）を検知した場合は自動で停止します。"
        alert.addButton(withTitle: "無期限で有効化")
        alert.addButton(withTitle: "キャンセル")
        return alert.runModal() == .alertFirstButtonReturn
    }

    /// 汎用のエラー表示。
    static func showError(_ message: String, detail: String? = nil) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = message
        if let detail { alert.informativeText = detail }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
