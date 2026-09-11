import Foundation
import IOKit.pwr_mgt
import os

/// 層A: IOKit の電源アサーション。
///
/// - `kIOPMAssertPreventUserIdleDisplaySleep` を作成し、無操作によるディスプレイスリープを抑止する。
/// - 30 秒ごとに `IOPMAssertionDeclareUserActivity` を呼び、OS に「ユーザーが操作中」と宣言する。
/// - `PreventSystemSleep` は使わない。蓋を閉じた際のスリープは妨げない。
/// - 停止・deinit で必ず `IOPMAssertionRelease` する。プロセスが強制終了された場合は
///   カーネル側（powerd）がプロセス単位でアサーションを回収する。
final class PowerAssertionManager {
    static let heartbeatInterval: TimeInterval = 30
    static let assertionReason = "StayAwake: user requested display to stay on"
    static let heartbeatName = "StayAwake heartbeat"

    private let logger = LogSubsystem.logger("power")
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.local.stayawake.power", qos: .utility)

    private var assertionID: IOPMAssertionID = 0
    private var activityID: IOPMAssertionID = 0
    private var active = false
    private var heartbeat: DispatchSourceTimer?

    var isActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return active
    }

    /// アサーションを作成する。既に有効なら何もしない。
    /// - Returns: 作成に成功（または既に有効）なら true。
    @discardableResult
    func start() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if active { return true }

        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            Self.assertionReason as CFString,
            &id
        )
        guard result == kIOReturnSuccess else {
            logger.error("IOPMAssertionCreateWithName failed: \(result, privacy: .public)")
            return false
        }
        assertionID = id
        active = true
        logger.info("display-sleep assertion created (id=\(id, privacy: .public))")

        declareUserActivityLocked()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + Self.heartbeatInterval,
            repeating: Self.heartbeatInterval,
            leeway: .seconds(3)
        )
        timer.setEventHandler { [weak self] in self?.heartbeatTick() }
        timer.resume()
        heartbeat = timer
        return true
    }

    /// アサーションを解放する。何度呼んでも安全。
    func stop() {
        lock.lock()
        defer { lock.unlock() }
        heartbeat?.cancel()
        heartbeat = nil
        if activityID != 0 {
            IOPMAssertionRelease(activityID)
            activityID = 0
        }
        if active {
            IOPMAssertionRelease(assertionID)
            logger.info("display-sleep assertion released (id=\(self.assertionID, privacy: .public))")
            assertionID = 0
            active = false
        }
    }

    deinit {
        stop()
    }

    private func heartbeatTick() {
        lock.lock()
        defer { lock.unlock() }
        guard active else { return }
        declareUserActivityLocked()
    }

    /// 呼び出し側で `lock` を保持していること。
    /// 同じ `activityID` を渡し続けると新規作成ではなく既存宣言の更新になる。
    private func declareUserActivityLocked() {
        let result = IOPMAssertionDeclareUserActivity(
            Self.heartbeatName as CFString,
            kIOPMUserActiveLocal,
            &activityID
        )
        if result == kIOReturnSuccess {
            logger.debug("declared user activity")
        } else {
            logger.error("IOPMAssertionDeclareUserActivity failed: \(result, privacy: .public)")
        }
    }
}
