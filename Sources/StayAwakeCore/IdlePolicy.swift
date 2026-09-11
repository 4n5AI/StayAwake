import Foundation

/// 直近の実操作からの経過秒数を返す。
/// OS API（`CGEventSource.secondsSinceLastEventType`）の挙動変化に備えて差し替え可能にしている。
public protocol IdleMonitoring {
    /// 直近のユーザー入力（マウス・キーボード等）からの経過秒数。
    func secondsSinceLastUserInput() -> TimeInterval
}

/// 層B（入力イベント模擬）を今このタイミングで発火させるべきかを判定する。
public enum IdlePolicy {
    /// 自前の模擬イベントを「最後の入力」として誤検知しないための許容誤差（秒）。
    public static let ownEventTolerance: TimeInterval = 1.5

    /// - Parameters:
    ///   - idleSeconds: 直近の入力イベントからの経過秒数（自前の模擬イベントも含む）。
    ///   - threshold: この秒数以内に実操作があればスキップする。
    ///   - secondsSinceOwnSimulatedEvent: 自前で最後に模擬イベントを送ってからの経過秒数。未送信なら nil。
    /// - Returns: true なら模擬イベントを送ってよい。
    public static func shouldSimulateInput(
        idleSeconds: TimeInterval,
        threshold: TimeInterval,
        secondsSinceOwnSimulatedEvent: TimeInterval?,
        tolerance: TimeInterval = ownEventTolerance
    ) -> Bool {
        // 最後の入力イベントが自分の模擬イベントだった場合、その後に実操作はない。
        // （実操作があれば idleSeconds はそれより小さくなる）
        if let own = secondsSinceOwnSimulatedEvent, abs(own - idleSeconds) <= tolerance {
            return true
        }
        return idleSeconds >= threshold
    }

    /// `IdleMonitoring` から直接判定する便宜メソッド。
    public static func shouldSimulateInput(
        using monitor: IdleMonitoring,
        threshold: TimeInterval,
        secondsSinceOwnSimulatedEvent: TimeInterval?
    ) -> Bool {
        shouldSimulateInput(
            idleSeconds: monitor.secondsSinceLastUserInput(),
            threshold: threshold,
            secondsSinceOwnSimulatedEvent: secondsSinceOwnSimulatedEvent
        )
    }
}
