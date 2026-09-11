import Foundation

/// 画面維持が停止した理由。通知文言とログに使う。
public enum StopReason: Equatable, Sendable {
    /// ユーザーがメニューの「停止」を選んだ。
    case userRequested
    /// 指定した時間（15分・1時間など）が満了した。
    case timerExpired
    /// 「時刻を指定して停止」で指定した時刻に到達した。
    case scheduledTimeReached
    /// 画面ロックを検知した。
    case screenLocked
    /// バッテリー駆動で残量がしきい値を下回った。
    case lowBattery(percent: Int)
    /// アプリ終了（メニューの終了・SIGTERM・applicationWillTerminate）。
    case appTerminating
    /// ログアウト・シャットダウン・再起動。
    case willPowerOff

    /// ユーザー操作以外で自動的に停止した場合 true。通知の対象になる。
    public var isAutomatic: Bool {
        switch self {
        case .userRequested, .appTerminating, .willPowerOff:
            return false
        case .timerExpired, .scheduledTimeReached, .screenLocked, .lowBattery:
            return true
        }
    }

    /// ログ用の短い識別子。
    public var logName: String {
        switch self {
        case .userRequested: return "userRequested"
        case .timerExpired: return "timerExpired"
        case .scheduledTimeReached: return "scheduledTimeReached"
        case .screenLocked: return "screenLocked"
        case .lowBattery(let p): return "lowBattery(\(p)%)"
        case .appTerminating: return "appTerminating"
        case .willPowerOff: return "willPowerOff"
        }
    }

    public var notificationTitle: String {
        "StayAwake を停止しました"
    }

    public var notificationBody: String {
        switch self {
        case .userRequested:
            return "停止しました。"
        case .timerExpired:
            return "指定した時間が経過したため、画面の維持を終了しました。"
        case .scheduledTimeReached:
            return "指定した時刻になったため、画面の維持を終了しました。"
        case .screenLocked:
            return "画面がロックされたため、画面の維持を終了しました。ロック解除後も自動では再開しません。"
        case .lowBattery(let percent):
            return "バッテリー残量が \(percent)% に低下したため、画面の維持を終了しました。"
        case .appTerminating:
            return "アプリの終了により停止しました。"
        case .willPowerOff:
            return "ログアウト／シャットダウンのため停止しました。"
        }
    }
}
