import AppKit
import ApplicationServices
import Foundation

/// アクセシビリティ権限（層Bの `CGEventPost` に必要）の確認と導線。
/// 権限の回避は一切行わない。付与できない端末では層Bを利用できない旨を表示するだけ。
@MainActor
enum AccessibilityPermission {
    /// 現在の権限状態（プロンプトは出さない）。
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// 権限がなければシステムのプロンプトを表示する。
    /// - Returns: 呼び出し時点で権限があれば true。
    @discardableResult
    static func requestIfNeeded() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// システム設定 › プライバシーとセキュリティ › アクセシビリティ を開く。
    static func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    /// 権限を付与できない端末向けの案内文（§10 既知の制約）。
    static let managedDeviceNotice =
        "システム設定で StayAwake を有効にできない場合（項目が灰色、または「管理者によって制限されています」と表示される場合）、"
        + "この端末では管理部門の設定により層Bを利用できません。管理部門に相談してください。本アプリはこの制限を回避しません。"
}
