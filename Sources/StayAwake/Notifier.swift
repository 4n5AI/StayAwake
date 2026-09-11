import Foundation
import os
import UserNotifications

/// `UserNotifications` による通知。
/// `UNUserNotificationCenter` は `.app` バンドル内で動作している場合のみ使える
/// （`swift run` で直接実行するとクラッシュするため、その場合はログ出力のみにフォールバックする）。
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let logger = LogSubsystem.logger("notifier")

    let isAvailable: Bool = Bundle.main.bundleIdentifier != nil
        && Bundle.main.bundleURL.pathExtension == "app"

    private var center: UNUserNotificationCenter? {
        isAvailable ? UNUserNotificationCenter.current() : nil
    }

    func requestAuthorizationIfPossible() {
        guard let center else {
            logger.notice("notifications unavailable (not running from an .app bundle)")
            return
        }
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { [logger = self.logger] granted, error in
            if let error {
                logger.error("notification authorization failed: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.info("notification authorization granted=\(granted, privacy: .public)")
            }
        }
    }

    func post(title: String, body: String) {
        guard let center else {
            logger.info("(notification) \(title, privacy: .public): \(body, privacy: .public)")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { [logger = self.logger] error in
            if let error {
                logger.error("failed to post notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: UNUserNotificationCenterDelegate

    /// アプリがアクティブなときもバナーを表示する。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
