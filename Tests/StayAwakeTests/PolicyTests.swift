import XCTest
@testable import StayAwakeCore

final class PolicyTests: XCTestCase {
    // MARK: 設定の既定値と範囲

    func testDefaultsMatchSpecification() {
        XCTAssertFalse(SettingsDefaults.layerBEnabled)
        XCTAssertEqual(SettingsDefaults.layerBInterval, 45)
        XCTAssertEqual(SettingsDefaults.layerBIntervalRange, 15...120)
        XCTAssertEqual(SettingsDefaults.realInputThreshold, 20)
        XCTAssertTrue(SettingsDefaults.stopOnLowBattery)
        XCTAssertEqual(SettingsDefaults.lowBatteryThresholdPercent, 15)
        XCTAssertFalse(SettingsDefaults.firstLaunchNoticeShown)
    }

    func testClampInterval() {
        XCTAssertEqual(SettingsDefaults.clampInterval(5), 15)
        XCTAssertEqual(SettingsDefaults.clampInterval(45), 45)
        XCTAssertEqual(SettingsDefaults.clampInterval(999), 120)
        XCTAssertEqual(SettingsDefaults.clampInterval(.nan), 15)
        XCTAssertEqual(SettingsDefaults.clampInterval(.infinity), 15)
    }

    func testClampThreshold() {
        XCTAssertEqual(SettingsDefaults.clampThreshold(0), 5)
        XCTAssertEqual(SettingsDefaults.clampThreshold(20), 20)
        XCTAssertEqual(SettingsDefaults.clampThreshold(500), 120)
    }

    // MARK: バッテリー

    func testStopsOnlyOnBatteryBelowThreshold() {
        XCTAssertTrue(BatteryPolicy.shouldStop(
            status: BatteryStatus(isOnBattery: true, percent: 14), enabled: true))
        XCTAssertFalse(BatteryPolicy.shouldStop(
            status: BatteryStatus(isOnBattery: true, percent: 15), enabled: true))
        XCTAssertFalse(BatteryPolicy.shouldStop(
            status: BatteryStatus(isOnBattery: false, percent: 5), enabled: true))
    }

    func testDisabledSettingNeverStops() {
        XCTAssertFalse(BatteryPolicy.shouldStop(
            status: BatteryStatus(isOnBattery: true, percent: 1), enabled: false))
    }

    func testNoBatteryNeverStops() {
        XCTAssertFalse(BatteryPolicy.shouldStop(status: nil, enabled: true))
    }

    func testCustomThreshold() {
        XCTAssertTrue(BatteryPolicy.shouldStop(
            status: BatteryStatus(isOnBattery: true, percent: 29), enabled: true, thresholdPercent: 30))
    }
}
