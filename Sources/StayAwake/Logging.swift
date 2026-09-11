import os

/// `os.Logger` のサブシステム名。汎用名で可。
/// ユーザーの入力内容・画面内容は一切ログに残さない（座標や文字も出力しない）。
enum LogSubsystem {
    static let name = "com.local.stayawake"

    static func logger(_ category: String) -> Logger {
        Logger(subsystem: name, category: category)
    }
}
