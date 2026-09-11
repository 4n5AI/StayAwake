import Foundation

/// 電源状態のスナップショット。
public struct BatteryStatus: Equatable, Sendable {
    /// バッテリー駆動中なら true（AC 接続中は false）。
    public var isOnBattery: Bool
    /// 残量（0〜100）。
    public var percent: Int

    public init(isOnBattery: Bool, percent: Int) {
        self.isOnBattery = isOnBattery
        self.percent = percent
    }
}

/// バッテリー低下時の自動停止判定。
public enum BatteryPolicy {
    /// 自動停止する残量のしきい値（この値「未満」で停止）。
    public static let defaultThresholdPercent = 15

    /// - Parameters:
    ///   - status: 現在の電源状態。バッテリーを持たない端末では nil。
    ///   - enabled: 設定「バッテリー低下時に自動停止」。
    ///   - thresholdPercent: しきい値（既定 15）。
    public static func shouldStop(
        status: BatteryStatus?,
        enabled: Bool,
        thresholdPercent: Int = defaultThresholdPercent
    ) -> Bool {
        guard enabled, let status else { return false }
        return status.isOnBattery && status.percent < thresholdPercent
    }
}
