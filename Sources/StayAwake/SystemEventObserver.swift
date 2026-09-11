import AppKit
import Foundation
import os

/// 画面ロック／スリープ／ログアウトなどのシステムイベントを監視する。
/// コールバックはすべてメインアクター上で呼ばれる。
@MainActor
final class SystemEventObserver {
    var onScreenLocked: (() -> Void)?
    var onScreenUnlocked: (() -> Void)?
    var onWillPowerOff: (() -> Void)?
    var onWillSleep: (() -> Void)?
    var onDidWake: (() -> Void)?

    private let logger = LogSubsystem.logger("system-events")
    private var tokens: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    static let screenIsLocked = Notification.Name("com.apple.screenIsLocked")
    static let screenIsUnlocked = Notification.Name("com.apple.screenIsUnlocked")

    func start() {
        guard tokens.isEmpty else { return }

        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Self.screenIsLocked) { [weak self] in
            self?.logger.info("screen locked")
            self?.onScreenLocked?()
        }
        observe(distributed, Self.screenIsUnlocked) { [weak self] in
            self?.logger.info("screen unlocked")
            self?.onScreenUnlocked?()
        }

        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willPowerOffNotification) { [weak self] in
            self?.logger.info("will power off / log out")
            self?.onWillPowerOff?()
        }
        observe(workspace, NSWorkspace.willSleepNotification) { [weak self] in
            self?.logger.info("system will sleep")
            self?.onWillSleep?()
        }
        observe(workspace, NSWorkspace.didWakeNotification) { [weak self] in
            self?.logger.info("system did wake")
            self?.onDidWake?()
        }
    }

    func stop() {
        for entry in tokens {
            entry.center.removeObserver(entry.token)
        }
        tokens.removeAll()
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        handler: @escaping @MainActor () -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
            Task { @MainActor in handler() }
        }
        tokens.append((center, token))
    }
}
