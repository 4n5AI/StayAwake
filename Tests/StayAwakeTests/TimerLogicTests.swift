import XCTest
@testable import StayAwakeCore

final class TimerLogicTests: XCTestCase {
    // MARK: プリセット

    func testPresetDurations() {
        XCTAssertEqual(KeepAwakePreset.minutes15.duration, 15 * 60)
        XCTAssertEqual(KeepAwakePreset.minutes30.duration, 30 * 60)
        XCTAssertEqual(KeepAwakePreset.hours1.duration, 60 * 60)
        XCTAssertEqual(KeepAwakePreset.hours2.duration, 2 * 60 * 60)
        XCTAssertEqual(KeepAwakePreset.hours4.duration, 4 * 60 * 60)
        XCTAssertNil(KeepAwakePreset.indefinite.duration)
    }

    func testDefaultPresetIsOneHour() {
        XCTAssertEqual(KeepAwakePreset.default, .hours1)
        XCTAssertEqual(KeepAwakePreset.hours1.menuTitle, "1時間（既定）")
        XCTAssertEqual(KeepAwakePreset.minutes15.menuTitle, "15分")
    }

    func testIndefiniteIsLastMenuEntry() {
        XCTAssertEqual(KeepAwakePreset.allCases.last, .indefinite)
        XCTAssertTrue(KeepAwakePreset.indefinite.isIndefinite)
        XCTAssertFalse(KeepAwakePreset.hours1.isIndefinite)
    }

    func testPresetEndDate() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(KeepAwakePreset.minutes30.endDate(from: now), now.addingTimeInterval(1800))
        XCTAssertNil(KeepAwakePreset.indefinite.endDate(from: now))
    }

    // MARK: 残り時間の表示

    func testDurationTextFormatting() {
        XCTAssertEqual(RemainingTimeFormatter.durationText(remainingSeconds: 42 * 60 + 59), "42分")
        XCTAssertEqual(RemainingTimeFormatter.durationText(remainingSeconds: 60), "1分")
        XCTAssertEqual(RemainingTimeFormatter.durationText(remainingSeconds: 3600 + 5 * 60), "1時間5分")
        XCTAssertEqual(RemainingTimeFormatter.durationText(remainingSeconds: 2 * 3600), "2時間")
        XCTAssertEqual(RemainingTimeFormatter.durationText(remainingSeconds: 30), "1分未満")
        XCTAssertEqual(RemainingTimeFormatter.durationText(remainingSeconds: -5), "1分未満")
    }

    func testMenuText() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(RemainingTimeFormatter.menuText(isActive: false, endDate: nil, now: now), "停止中")
        XCTAssertEqual(RemainingTimeFormatter.menuText(isActive: false, endDate: now.addingTimeInterval(600), now: now), "停止中")
        XCTAssertEqual(RemainingTimeFormatter.menuText(isActive: true, endDate: nil, now: now), "残り ∞（無期限）")
        XCTAssertEqual(
            RemainingTimeFormatter.menuText(isActive: true, endDate: now.addingTimeInterval(42 * 60), now: now),
            "残り 42分"
        )
    }

    func testCompactText() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertNil(RemainingTimeFormatter.compactText(isActive: false, endDate: nil, now: now))
        XCTAssertEqual(RemainingTimeFormatter.compactText(isActive: true, endDate: nil, now: now), "∞")
        XCTAssertEqual(
            RemainingTimeFormatter.compactText(isActive: true, endDate: now.addingTimeInterval(3600), now: now),
            "1時間"
        )
    }

    // MARK: 時刻指定停止

    private var tokyo: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        tokyo.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testNextOccurrenceLaterToday() {
        let now = date(2026, 9, 11, 10, 0)
        let end = StopTimeCalculator.nextOccurrence(hour: 18, minute: 30, after: now, calendar: tokyo)
        XCTAssertEqual(end, date(2026, 9, 11, 18, 30))
    }

    func testNextOccurrenceRollsToTomorrowWhenPast() {
        let now = date(2026, 9, 11, 10, 0)
        let end = StopTimeCalculator.nextOccurrence(hour: 9, minute: 0, after: now, calendar: tokyo)
        XCTAssertEqual(end, date(2026, 9, 12, 9, 0))
    }

    func testNextOccurrenceRollsToTomorrowWhenEqualToNow() {
        let now = date(2026, 9, 11, 10, 0)
        let end = StopTimeCalculator.nextOccurrence(hour: 10, minute: 0, after: now, calendar: tokyo)
        XCTAssertEqual(end, date(2026, 9, 12, 10, 0))
    }

    func testNextOccurrenceAcrossMonthEnd() {
        let now = date(2026, 9, 30, 23, 0)
        let end = StopTimeCalculator.nextOccurrence(hour: 1, minute: 0, after: now, calendar: tokyo)
        XCTAssertEqual(end, date(2026, 10, 1, 1, 0))
    }

    func testNextOccurrenceRejectsInvalidInput() {
        let now = date(2026, 9, 11, 10, 0)
        XCTAssertNil(StopTimeCalculator.nextOccurrence(hour: 24, minute: 0, after: now, calendar: tokyo))
        XCTAssertNil(StopTimeCalculator.nextOccurrence(hour: 10, minute: 60, after: now, calendar: tokyo))
    }

    func testHourMinuteExtraction() {
        let hm = StopTimeCalculator.hourMinute(of: date(2026, 9, 11, 18, 45), calendar: tokyo)
        XCTAssertEqual(hm.hour, 18)
        XCTAssertEqual(hm.minute, 45)
    }

    // MARK: 停止理由

    func testAutomaticStopReasonsAreNotified() {
        XCTAssertTrue(StopReason.timerExpired.isAutomatic)
        XCTAssertTrue(StopReason.scheduledTimeReached.isAutomatic)
        XCTAssertTrue(StopReason.screenLocked.isAutomatic)
        XCTAssertTrue(StopReason.lowBattery(percent: 10).isAutomatic)
        XCTAssertFalse(StopReason.userRequested.isAutomatic)
        XCTAssertFalse(StopReason.appTerminating.isAutomatic)
        XCTAssertFalse(StopReason.willPowerOff.isAutomatic)
    }
}
