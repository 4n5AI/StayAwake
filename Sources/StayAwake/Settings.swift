import Foundation
import StayAwakeCore

/// `UserDefaults`（標準 suite）に永続化する設定。
/// SwiftUI の `Settings` シーンと名前が衝突しないよう `AppSettings` としている。
@MainActor
final class AppSettings: ObservableObject {
    enum Key {
        static let layerBEnabled = "layerB.enabled"
        static let layerBInterval = "layerB.intervalSeconds"
        static let realInputThreshold = "layerB.realInputThresholdSeconds"
        static let stopOnLowBattery = "autoStop.lowBattery"
        static let firstLaunchNoticeShown = "firstLaunchNotice.shown"
    }

    private let defaults: UserDefaults

    /// 設定変更時に呼ばれる（`KeepAwakeController` が層Bの再構成に使う）。
    var onChange: (() -> Void)?

    /// 層B（入力イベント模擬）を使うか。
    @Published var layerBEnabled: Bool {
        didSet {
            defaults.set(layerBEnabled, forKey: Key.layerBEnabled)
            onChange?()
        }
    }

    /// 層Bの送信間隔（秒）。15〜120。
    @Published var layerBInterval: TimeInterval {
        didSet {
            defaults.set(SettingsDefaults.clampInterval(layerBInterval), forKey: Key.layerBInterval)
            onChange?()
        }
    }

    /// 直近この秒数以内に実操作があれば層Bはイベントを送らない。
    @Published var realInputThreshold: TimeInterval {
        didSet {
            defaults.set(SettingsDefaults.clampThreshold(realInputThreshold), forKey: Key.realInputThreshold)
            onChange?()
        }
    }

    /// バッテリー駆動で残量 15% 未満になったら自動停止する。
    @Published var stopOnLowBattery: Bool {
        didSet {
            defaults.set(stopOnLowBattery, forKey: Key.stopOnLowBattery)
            onChange?()
        }
    }

    /// 初回起動時の注意画面を表示済みか。
    @Published var firstLaunchNoticeShown: Bool {
        didSet { defaults.set(firstLaunchNoticeShown, forKey: Key.firstLaunchNoticeShown) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        layerBEnabled = (defaults.object(forKey: Key.layerBEnabled) as? Bool) ?? SettingsDefaults.layerBEnabled
        layerBInterval = SettingsDefaults.clampInterval(
            (defaults.object(forKey: Key.layerBInterval) as? Double) ?? SettingsDefaults.layerBInterval)
        realInputThreshold = SettingsDefaults.clampThreshold(
            (defaults.object(forKey: Key.realInputThreshold) as? Double) ?? SettingsDefaults.realInputThreshold)
        stopOnLowBattery = (defaults.object(forKey: Key.stopOnLowBattery) as? Bool) ?? SettingsDefaults.stopOnLowBattery
        firstLaunchNoticeShown = (defaults.object(forKey: Key.firstLaunchNoticeShown) as? Bool)
            ?? SettingsDefaults.firstLaunchNoticeShown
    }

    /// 層Bに渡す現在の構成（クランプ済み）。
    var layerBConfiguration: InputSimulator.Configuration {
        InputSimulator.Configuration(
            interval: SettingsDefaults.clampInterval(layerBInterval),
            realInputThreshold: SettingsDefaults.clampThreshold(realInputThreshold)
        )
    }
}
