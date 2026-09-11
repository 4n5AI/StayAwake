import CoreGraphics
import Foundation
import os
import StayAwakeCore

/// 層B: 入力イベント模擬（オプション）。
///
/// 一定間隔で「直近に実操作があったか」を確認し、なければマウスカーソルを +1px 動かして
/// 即座に元の位置へ戻す `mouseMoved` イベントを `CGEventPost` する。
/// クリック・キー入力は一切生成しない。アクセシビリティ権限が必要。
final class InputSimulator {
    struct Configuration: Equatable {
        /// 模擬イベントの送信間隔（秒）。
        var interval: TimeInterval
        /// 直近この秒数以内に実操作があればスキップする。
        var realInputThreshold: TimeInterval
    }

    private let logger = LogSubsystem.logger("input-simulator")
    private let queue = DispatchQueue(label: "com.local.stayawake.input-simulator", qos: .utility)
    private let idleMonitor: IdleMonitoring

    // 以下は `queue` 上でのみ触る。
    private var configuration: Configuration
    private var timer: DispatchSourceTimer?
    private var lastSimulatedAt: Date?

    init(idleMonitor: IdleMonitoring, configuration: Configuration) {
        self.idleMonitor = idleMonitor
        self.configuration = configuration
    }

    deinit {
        timer?.cancel()
    }

    var isRunning: Bool {
        queue.sync { timer != nil }
    }

    func start() {
        queue.async { [self] in
            guard self.timer == nil else { return }
            self.scheduleTimerOnQueue()
            self.logger.info(
                "layer B started (interval=\(self.configuration.interval, privacy: .public)s, threshold=\(self.configuration.realInputThreshold, privacy: .public)s)"
            )
        }
    }

    func stop() {
        queue.async { [self] in
            guard self.timer != nil else { return }
            self.timer?.cancel()
            self.timer = nil
            self.lastSimulatedAt = nil
            self.logger.info("layer B stopped")
        }
    }

    func update(configuration new: Configuration) {
        queue.async { [self] in
            guard new != self.configuration else { return }
            self.configuration = new
            if self.timer != nil {
                self.timer?.cancel()
                self.timer = nil
                self.scheduleTimerOnQueue()
                self.logger.info(
                    "layer B reconfigured (interval=\(new.interval, privacy: .public)s, threshold=\(new.realInputThreshold, privacy: .public)s)"
                )
            }
        }
    }

    // MARK: - queue 上の処理

    private func scheduleTimerOnQueue() {
        let interval = configuration.interval
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now() + interval, repeating: interval, leeway: .seconds(2))
        source.setEventHandler { [weak self] in self?.tick() }
        source.resume()
        timer = source
    }

    private func tick() {
        // 画面ロック中は一切動かない（通常はロック検知で controller が停止済み。二重の安全策）。
        if Self.isSessionLocked() {
            logger.info("skip: screen is locked")
            return
        }

        let idle = idleMonitor.secondsSinceLastUserInput()
        let sinceOwn = lastSimulatedAt.map { Date().timeIntervalSince($0) }
        let shouldSimulate = IdlePolicy.shouldSimulateInput(
            idleSeconds: idle,
            threshold: configuration.realInputThreshold,
            secondsSinceOwnSimulatedEvent: sinceOwn
        )
        guard shouldSimulate else {
            logger.info("skip: real user input \(Int(idle), privacy: .public)s ago (< \(Int(self.configuration.realInputThreshold), privacy: .public)s)")
            return
        }

        if jiggle() {
            lastSimulatedAt = Date()
            logger.info("posted synthetic mouseMoved (+1px and back); idle was \(Int(idle), privacy: .public)s")
        }
    }

    /// カーソルを +1px 動かして戻す。座標はログに残さない。
    private func jiggle() -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            logger.error("CGEventSource unavailable")
            return false
        }
        // CGEvent(source: nil).location は CG 座標系（左上原点）の現在位置。
        // NSEvent.mouseLocation（左下原点）からの座標変換は不要。
        guard let current = CGEvent(source: nil)?.location else {
            logger.error("could not read cursor location")
            return false
        }
        let moved = CGPoint(x: current.x + 1, y: current.y)

        guard
            let forward = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                                  mouseCursorPosition: moved, mouseButton: .left),
            let back = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                               mouseCursorPosition: current, mouseButton: .left)
        else {
            logger.error("could not create mouseMoved events")
            return false
        }
        forward.post(tap: .cghidEventTap)
        usleep(20_000)
        back.post(tap: .cghidEventTap)
        return true
    }

    private static func isSessionLocked() -> Bool {
        guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        return (dict["CGSSessionScreenIsLocked"] as? Bool) ?? false
    }
}
