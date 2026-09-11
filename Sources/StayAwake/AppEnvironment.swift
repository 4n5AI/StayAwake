import AppKit
import Foundation
import os
import StayAwakeCore
import SwiftUI

/// アプリ全体で共有する長寿命オブジェクトの置き場。
/// `AppDelegate` と SwiftUI ビューの双方から参照する。
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let settings: AppSettings
    let appState: AppState
    let notifier: Notifier
    let controller: KeepAwakeController
    let windows: WindowPresenter

    private let logger = LogSubsystem.logger("app")
    private var signalSources: [DispatchSourceSignal] = []
    private var bootstrapped = false

    enum WindowID {
        static let firstLaunch = "first-launch-notice"
        static let settings = "settings"
        static let stopTime = "stop-time-picker"
    }

    private init() {
        settings = AppSettings()
        appState = AppState()
        notifier = Notifier()
        controller = KeepAwakeController(state: appState, settings: settings, notifier: notifier)
        windows = WindowPresenter()
    }

    /// `applicationDidFinishLaunching` から呼ぶ。
    func bootstrap() {
        guard !bootstrapped else { return }
        bootstrapped = true
        logger.info("launching (bundle=\(Bundle.main.bundleIdentifier ?? "none", privacy: .public))")

        notifier.requestAuthorizationIfPossible()
        controller.bootstrap()
        installSignalHandlers()

        if !settings.firstLaunchNoticeShown {
            showFirstLaunchNotice()
        }
    }

    /// 停止処理をしてからアプリを終了する。
    func terminate(reason: StopReason) {
        controller.stop(reason: reason)
        NSApplication.shared.terminate(nil)
    }

    // MARK: - ウィンドウ

    func showFirstLaunchNotice() {
        windows.show(id: WindowID.firstLaunch, title: "StayAwake をご利用になる前に") {
            FirstLaunchNoticeView { [weak self] in
                self?.settings.firstLaunchNoticeShown = true
                self?.windows.close(id: WindowID.firstLaunch)
            }
        }
    }

    func showSettings() {
        windows.show(id: WindowID.settings, title: "StayAwake 設定") {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(appState)
        }
    }

    func showStopTimePicker() {
        windows.show(id: WindowID.stopTime, title: "時刻を指定して停止") {
            StopTimePickerView(
                onConfirm: { [weak self] endDate in
                    self?.controller.start(untilClockTime: endDate)
                    self?.windows.close(id: WindowID.stopTime)
                },
                onCancel: { [weak self] in
                    self?.windows.close(id: WindowID.stopTime)
                }
            )
        }
    }

    // MARK: - シグナル

    /// SIGTERM / SIGINT / SIGHUP を受けたら停止処理（アサーション解放）をしてから終了する。
    /// SIGKILL は捕捉できないが、その場合は powerd がプロセス単位でアサーションを回収する。
    private func installSignalHandlers() {
        for sig in [SIGTERM, SIGINT, SIGHUP] {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler {
                Task { @MainActor in
                    AppEnvironment.shared.logger.info("signal \(sig, privacy: .public) received; stopping")
                    AppEnvironment.shared.terminate(reason: .appTerminating)
                }
            }
            source.resume()
            signalSources.append(source)
        }
    }
}
