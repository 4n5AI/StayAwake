import Foundation
import StayAwakeCore

/// UI に表示する状態。更新は `KeepAwakeController` がメインスレッドで行う。
@MainActor
final class AppState: ObservableObject {
    /// 画面維持が有効かどうか。
    @Published var isActive = false
    /// 停止予定時刻。有効かつ nil なら無期限。
    @Published var endDate: Date?
    /// メニュー先頭に表示する文字列（「残り 42分」「停止中」）。
    @Published var menuText: String = RemainingTimeFormatter.inactiveText
    /// メニューバーアイコン横に表示する短い文字列（「42分」「∞」）。無効時は nil。
    @Published var compactText: String?
    /// 層B（入力イベント模擬）が実際に動作しているか。
    @Published var layerBActive = false
    /// ユーザーに見せる補足メッセージ（エラーなど）。
    @Published var message: String?

    /// メニューバーアイコン。無効時はアウトライン、有効時は塗り。
    var iconName: String { isActive ? "eye.fill" : "eye" }

    func refreshTexts(now: Date = Date()) {
        menuText = RemainingTimeFormatter.menuText(isActive: isActive, endDate: endDate, now: now)
        compactText = RemainingTimeFormatter.compactText(isActive: isActive, endDate: endDate, now: now)
    }
}
