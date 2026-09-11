import Foundation
import IOKit.ps
import os
import StayAwakeCore

/// 電源状態（AC／バッテリー、残量）を監視する。
/// ポーリングではなく `IOPSNotificationCreateRunLoopSource` の変化通知を使う。
final class BatteryMonitor {
    /// 電源状態が変化したときに呼ばれる（メインアクター上）。
    var onUpdate: (@MainActor (BatteryStatus) -> Void)?

    private let logger = LogSubsystem.logger("battery")
    private var source: CFRunLoopSource?

    func start() {
        guard source == nil else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue().publish()
        }
        guard let runLoopSource = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() else {
            logger.error("IOPSNotificationCreateRunLoopSource failed")
            return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        source = runLoopSource
        logger.info("battery monitoring started")
        publish()
    }

    func stop() {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            self.source = nil
        }
    }

    deinit {
        stop()
    }

    /// 現在の電源状態。内蔵バッテリーがない端末では nil。
    func currentStatus() -> BatteryStatus? {
        Self.readStatus()
    }

    private func publish() {
        guard let status = Self.readStatus() else { return }
        let handler = onUpdate
        Task { @MainActor in handler?(status) }
    }

    static func readStatus() -> BatteryStatus? {
        guard
            let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue()
        else { return nil }

        for item in list as NSArray {
            guard
                let description = IOPSGetPowerSourceDescription(blob, item as CFTypeRef)?
                    .takeUnretainedValue() as? [String: Any]
            else { continue }
            guard (description[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else { continue }

            let state = description[kIOPSPowerSourceStateKey] as? String
            let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maximum = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let percent = maximum > 0
                ? Int((Double(current) / Double(maximum) * 100).rounded())
                : current
            return BatteryStatus(
                isOnBattery: state == kIOPSBatteryPowerValue,
                percent: min(max(percent, 0), 100)
            )
        }
        return nil
    }
}
