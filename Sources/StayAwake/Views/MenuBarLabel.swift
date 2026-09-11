import SwiftUI

/// メニューバーに表示するアイコン＋残り時間。
/// 無効時: `eye`（アウトライン）、有効時: `eye.fill` ＋「42分」／「∞」。
struct MenuBarLabel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: appState.iconName)
            if let text = appState.compactText {
                Text(text)
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(appState.isActive ? "StayAwake 有効" : "StayAwake 停止中")
    }
}
