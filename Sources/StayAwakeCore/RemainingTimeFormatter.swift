import Foundation

/// 残り時間の表示文字列を組み立てる。UI から切り離してテスト可能にしている。
public enum RemainingTimeFormatter {
    public static let infinitySymbol = "∞"
    public static let inactiveText = "停止中"

    /// 残り秒数を「時間・分」に分解する。分は切り捨て。
    public static func components(remainingSeconds: TimeInterval) -> (hours: Int, minutes: Int) {
        let clamped = max(0, remainingSeconds)
        let totalMinutes = Int(clamped / 60)
        return (totalMinutes / 60, totalMinutes % 60)
    }

    /// 「1時間5分」「42分」「1分未満」形式。
    public static func durationText(remainingSeconds: TimeInterval) -> String {
        if remainingSeconds < 60 { return "1分未満" }
        let c = components(remainingSeconds: remainingSeconds)
        switch (c.hours, c.minutes) {
        case (0, let m): return "\(m)分"
        case (let h, 0): return "\(h)時間"
        case (let h, let m): return "\(h)時間\(m)分"
        }
    }

    /// メニュー先頭の表示。有効でない場合は「停止中」。
    public static func menuText(isActive: Bool, endDate: Date?, now: Date = Date()) -> String {
        guard isActive else { return inactiveText }
        guard let endDate else { return "残り \(infinitySymbol)（無期限）" }
        return "残り \(durationText(remainingSeconds: endDate.timeIntervalSince(now)))"
    }

    /// メニューバーアイコン横の短い表示。無効時は nil（アイコンのみ）。
    public static func compactText(isActive: Bool, endDate: Date?, now: Date = Date()) -> String? {
        guard isActive else { return nil }
        guard let endDate else { return infinitySymbol }
        return durationText(remainingSeconds: endDate.timeIntervalSince(now))
    }
}
