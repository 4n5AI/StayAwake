import Foundation

/// 設定の既定値と許容範囲。UserDefaults への保存は App 側（`AppSettings`）が担当する。
public enum SettingsDefaults {
    // MARK: 層B（入力イベント模擬）

    /// 層Bは既定でオフ。設定画面で明示的にオンにした場合のみ動作する。
    public static let layerBEnabled = false

    /// 模擬イベントの送信間隔（秒）。
    public static let layerBInterval: TimeInterval = 45
    public static let layerBIntervalRange: ClosedRange<TimeInterval> = 15...120

    /// 直近この秒数以内に実操作があればイベントを送らない。
    public static let realInputThreshold: TimeInterval = 20
    public static let realInputThresholdRange: ClosedRange<TimeInterval> = 5...120

    // MARK: 自動停止

    public static let stopOnLowBattery = true
    public static let lowBatteryThresholdPercent = BatteryPolicy.defaultThresholdPercent

    // MARK: その他

    public static let firstLaunchNoticeShown = false

    // MARK: クランプ

    public static func clampInterval(_ value: TimeInterval) -> TimeInterval {
        clamp(value, to: layerBIntervalRange)
    }

    public static func clampThreshold(_ value: TimeInterval) -> TimeInterval {
        clamp(value, to: realInputThresholdRange)
    }

    static func clamp(_ value: TimeInterval, to range: ClosedRange<TimeInterval>) -> TimeInterval {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
