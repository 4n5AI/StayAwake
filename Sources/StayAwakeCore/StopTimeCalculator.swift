import Foundation

/// 「時刻を指定して停止」の停止予定時刻を計算する。
public enum StopTimeCalculator {
    /// `hour:minute` の次の到来時刻を返す。
    /// 今日のその時刻が `now` より後ならば今日、そうでなければ翌日。
    public static func nextOccurrence(
        hour: Int,
        minute: Int,
        after now: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let today = calendar.date(from: comps) else { return nil }
        if today > now { return today }
        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    /// `Date` から時・分を取り出す（DatePicker の値を渡す用途）。
    public static func hourMinute(of date: Date, calendar: Calendar = .current) -> (hour: Int, minute: Int) {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0, comps.minute ?? 0)
    }
}
