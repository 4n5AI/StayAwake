import Foundation

/// メニューから選べる維持時間のプリセット。
/// `allCases` の順序がそのままメニューの並び順になる（無期限は末尾）。
public enum KeepAwakePreset: CaseIterable, Hashable, Sendable {
    case minutes15
    case minutes30
    case hours1
    case hours2
    case hours4
    case indefinite

    /// 既定の選択肢（1時間）。
    public static let `default`: KeepAwakePreset = .hours1

    /// 維持する秒数。無期限は nil。
    public var duration: TimeInterval? {
        switch self {
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hours1: return 60 * 60
        case .hours2: return 2 * 60 * 60
        case .hours4: return 4 * 60 * 60
        case .indefinite: return nil
        }
    }

    public var isIndefinite: Bool { self == .indefinite }

    public var title: String {
        switch self {
        case .minutes15: return "15分"
        case .minutes30: return "30分"
        case .hours1: return "1時間"
        case .hours2: return "2時間"
        case .hours4: return "4時間"
        case .indefinite: return "無期限"
        }
    }

    /// メニュー表示用タイトル。既定の選択肢には印を付ける。
    public var menuTitle: String {
        self == Self.default ? "\(title)（既定）" : title
    }

    /// `now` を起点にした停止予定時刻。無期限は nil。
    public func endDate(from now: Date = Date()) -> Date? {
        duration.map { now.addingTimeInterval($0) }
    }
}
