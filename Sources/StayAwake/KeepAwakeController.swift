import AppKit
import Foundation
import os
import StayAwakeCore

/// 開始／停止の司令塔。層A（電源アサーション）と層B（入力模擬）を束ね、
/// タイマー・画面ロック・バッテリーによる自動停止を扱う。
@MainActor
final class KeepAwakeController: ObservableObject {
    /// 残り時間表示を更新する間隔（秒）。ポーリング負荷を抑えるため 30 秒以上。
    static let refreshInterval: TimeInterval = 30

    private let logger = LogSubsystem.logger("controller")
    private let state: AppState
    private let settings: AppSettings
    private let notifier: Notifier

    private let power = PowerAssertionManager()
    private let input: InputSimulator
    private let systemEvents: SystemEventObserver
    private let battery = BatteryMonitor()

    private var expiryTimer: Timer?
    private var refreshTimer: Timer?
    /// 「時刻を指定して停止」で開始したか（通知文言の区別に使う）。
    private var stopsAtScheduledClockTime = false
    private var bootstrapped = false

    init(
        state: AppState,
        settings: AppSettings,
        notifier: Notifier,
        idleMonitor: IdleMonitoring = CGEventIdleMonitor()
    ) {
        self.state = state
        self.settings = settings
        self.notifier = notifier
        self.input = InputSimulator(idleMonitor: idleMonitor, configuration: settings.layerBConfiguration)
        // @MainActor 型は init 内で明示的に生成する（プロパティ既定値式での生成を避ける）。
        self.systemEvents = SystemEventObserver()
    }

    /// 監視の開始。アプリ起動後に一度だけ呼ぶ。
    func bootstrap() {
        guard !bootstrapped else { return }
        bootstrapped = true

        systemEvents.onScreenLocked = { [weak self] in
            self?.stop(reason: .screenLocked)
        }
        systemEvents.onWillPowerOff = { [weak self] in
            self?.stop(reason: .willPowerOff)
        }
        systemEvents.onDidWake = { [weak self] in
            // スリープ中に満了していれば即停止する。
            self?.refreshRemaining()
        }
        systemEvents.start()

        battery.onUpdate = { [weak self] status in
            self?.handleBattery(status)
        }
        battery.start()

        settings.onChange = { [weak self] in
            self?.applySettings()
        }
    }

    // MARK: - 開始 / 停止

    /// プリセット（15分〜無期限）で開始する。有効中に呼ぶと時間を上書きする。
    func start(preset: KeepAwakePreset) {
        start(until: preset.endDate(), scheduledClockTime: false, label: preset.title)
    }

    /// 指定時刻まで有効化する。
    func start(untilClockTime endDate: Date) {
        start(until: endDate, scheduledClockTime: true, label: "until clock time")
    }

    private func start(until endDate: Date?, scheduledClockTime: Bool, label: String) {
        state.message = nil

        if !power.isActive {
            guard power.start() else {
                logger.error("failed to create power assertion")
                state.message = "電源アサーションの作成に失敗しました。"
                Dialogs.showError("画面の維持を開始できませんでした。", detail: "電源アサーション（IOKit）の作成に失敗しました。")
                return
            }
        }

        cancelTimers()
        stopsAtScheduledClockTime = scheduledClockTime
        state.isActive = true
        state.endDate = endDate
        scheduleTimers(endDate: endDate)
        applyLayerB()
        refreshRemaining()

        let endDescription = endDate.map { ISO8601DateFormatter().string(from: $0) } ?? "indefinite"
        logger.info("started (\(label, privacy: .public)) until \(endDescription, privacy: .public)")

        // 既にバッテリー低下状態なら開始直後に自動停止（通知あり）。
        if let status = battery.currentStatus() {
            handleBattery(status)
        }
    }

    /// 停止する。何度呼んでも安全（層Aの解放は毎回試みる）。
    func stop(reason: StopReason) {
        let wasActive = state.isActive
        cancelTimers()
        input.stop()
        power.stop()

        state.isActive = false
        state.endDate = nil
        state.layerBActive = false
        state.refreshTexts()

        guard wasActive else { return }
        logger.info("stopped: \(reason.logName, privacy: .public)")
        if reason.isAutomatic {
            notifier.post(title: reason.notificationTitle, body: reason.notificationBody)
        }
    }

    // MARK: - 層B

    private func applyLayerB() {
        let wantsLayerB = state.isActive && settings.layerBEnabled
        guard wantsLayerB else {
            input.stop()
            state.layerBActive = false
            return
        }
        guard AccessibilityPermission.isTrusted() else {
            logger.notice("layer B requested but accessibility permission is missing; running with layer A only")
            input.stop()
            state.layerBActive = false
            state.message = "アクセシビリティ権限がないため層Bは動作していません（層Aのみ）。"
            return
        }
        input.update(configuration: settings.layerBConfiguration)
        input.start()
        state.layerBActive = true
    }

    private func applySettings() {
        applyLayerB()
        if state.isActive, let status = battery.currentStatus() {
            handleBattery(status)
        }
    }

    // MARK: - タイマー

    private func scheduleTimers(endDate: Date?) {
        if let endDate {
            let timer = Timer(fire: endDate, interval: 0, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.handleExpiry() }
            }
            timer.tolerance = 1
            RunLoop.main.add(timer, forMode: .common)
            expiryTimer = timer
        }

        let refresh = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshRemaining() }
        }
        refresh.tolerance = 5
        RunLoop.main.add(refresh, forMode: .common)
        refreshTimer = refresh
    }

    private func cancelTimers() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func handleExpiry() {
        guard state.isActive else { return }
        guard let endDate = state.endDate else { return }
        if Date() >= endDate.addingTimeInterval(-0.5) {
            stop(reason: stopsAtScheduledClockTime ? .scheduledTimeReached : .timerExpired)
        } else {
            // 早すぎる発火（通常は起きない）。予定時刻で再スケジュール。
            expiryTimer?.invalidate()
            let timer = Timer(fire: endDate, interval: 0, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.handleExpiry() }
            }
            RunLoop.main.add(timer, forMode: .common)
            expiryTimer = timer
        }
    }

    /// 残り時間表示を更新し、スリープ復帰などで満了を過ぎていれば停止する。
    private func refreshRemaining() {
        guard state.isActive else {
            state.refreshTexts()
            return
        }
        if let endDate = state.endDate, Date() >= endDate {
            handleExpiry()
            return
        }
        state.refreshTexts()
    }

    // MARK: - バッテリー

    private func handleBattery(_ status: BatteryStatus) {
        guard state.isActive else { return }
        if BatteryPolicy.shouldStop(status: status, enabled: settings.stopOnLowBattery) {
            stop(reason: .lowBattery(percent: status.percent))
        }
    }
}
