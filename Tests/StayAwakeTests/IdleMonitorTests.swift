import XCTest
@testable import StayAwakeCore

/// テスト用の差し替え実装。
private struct FakeIdleMonitor: IdleMonitoring {
    var idle: TimeInterval
    func secondsSinceLastUserInput() -> TimeInterval { idle }
}

final class IdleMonitorTests: XCTestCase {
    private let threshold: TimeInterval = 20

    func testSimulatesWhenIdleLongerThanThreshold() {
        XCTAssertTrue(IdlePolicy.shouldSimulateInput(
            idleSeconds: 25, threshold: threshold, secondsSinceOwnSimulatedEvent: nil))
        XCTAssertTrue(IdlePolicy.shouldSimulateInput(
            idleSeconds: 20, threshold: threshold, secondsSinceOwnSimulatedEvent: nil))
    }

    func testSkipsWhenUserRecentlyActive() {
        XCTAssertFalse(IdlePolicy.shouldSimulateInput(
            idleSeconds: 5, threshold: threshold, secondsSinceOwnSimulatedEvent: nil))
        XCTAssertFalse(IdlePolicy.shouldSimulateInput(
            idleSeconds: 19.9, threshold: threshold, secondsSinceOwnSimulatedEvent: nil))
    }

    /// 直近の入力が自分の模擬イベントだった場合は、閾値未満でも「実操作なし」と判定する。
    func testOwnSimulatedEventIsNotTreatedAsRealInput() {
        XCTAssertTrue(IdlePolicy.shouldSimulateInput(
            idleSeconds: 10.4, threshold: threshold, secondsSinceOwnSimulatedEvent: 10))
        XCTAssertTrue(IdlePolicy.shouldSimulateInput(
            idleSeconds: 15, threshold: threshold, secondsSinceOwnSimulatedEvent: 15.2))
    }

    /// 自分の模擬イベントの後に実操作があれば（idle が own より明確に小さい）スキップする。
    func testRealInputAfterOwnEventSkips() {
        XCTAssertFalse(IdlePolicy.shouldSimulateInput(
            idleSeconds: 3, threshold: threshold, secondsSinceOwnSimulatedEvent: 45))
        XCTAssertFalse(IdlePolicy.shouldSimulateInput(
            idleSeconds: 18, threshold: threshold, secondsSinceOwnSimulatedEvent: 45))
    }

    func testToleranceBoundary() {
        // 差が許容誤差ちょうどなら自分のイベントとみなす
        XCTAssertTrue(IdlePolicy.shouldSimulateInput(
            idleSeconds: 8.5, threshold: threshold, secondsSinceOwnSimulatedEvent: 10, tolerance: 1.5))
        // 許容誤差を超えて小さければ実操作あり
        XCTAssertFalse(IdlePolicy.shouldSimulateInput(
            idleSeconds: 8.4, threshold: threshold, secondsSinceOwnSimulatedEvent: 10, tolerance: 1.5))
    }

    func testDecisionThroughProtocol() {
        XCTAssertTrue(IdlePolicy.shouldSimulateInput(
            using: FakeIdleMonitor(idle: 60), threshold: threshold, secondsSinceOwnSimulatedEvent: nil))
        XCTAssertFalse(IdlePolicy.shouldSimulateInput(
            using: FakeIdleMonitor(idle: 1), threshold: threshold, secondsSinceOwnSimulatedEvent: nil))
    }
}
