import Foundation
import ServiceManagement

/// ログイン時に起動（`SMAppService.mainApp`）。状態はシステムが保持するため UserDefaults には保存しない。
enum LaunchAtLogin {
    /// `.app` バンドルとして実行されている場合のみ利用可能（`swift run` 直実行では不可）。
    static var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    static var isEnabled: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// システム設定で承認待ちになっている状態。
    static var requiresApproval: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .requiresApproval
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
