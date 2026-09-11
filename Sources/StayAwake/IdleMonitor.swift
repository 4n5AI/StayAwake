import CoreGraphics
import Foundation
import StayAwakeCore

/// `CGEventSource.secondsSinceLastEventType` を使った `IdleMonitoring` の実装。
///
/// まず「任意のイベント種別」（`kCGAnyInputEventType` = `~0`）で問い合わせ、
/// それが利用できない場合は主要なイベント種別を個別に取得して最小値を採用する。
final class CGEventIdleMonitor: IdleMonitoring {
    /// フォールバック時に確認するイベント種別。
    private static let fallbackTypes: [CGEventType] = [
        .mouseMoved,
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .leftMouseDragged,
        .rightMouseDragged,
        .scrollWheel,
        .keyDown,
        .flagsChanged,
    ]

    /// `kCGAnyInputEventType` 相当。
    private static let anyInputEventType: CGEventType? = CGEventType(rawValue: ~0)

    func secondsSinceLastUserInput() -> TimeInterval {
        if let any = Self.anyInputEventType {
            return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: any)
        }
        return Self.fallbackTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0
    }
}
