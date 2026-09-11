import AppKit
import StayAwakeCore
import SwiftUI

/// メニューバーから開くメニューの中身（`MenuBarExtra` の `.menu` スタイル）。
struct MenuContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var controller: KeepAwakeController

    private var quickStartTitle: String {
        "すぐに有効化（\(KeepAwakePreset.default.title)）"
    }

    var body: some View {
        // 先頭: 状態表示（「残り 42分」／「停止中」）
        Text(appState.menuText)
        if appState.layerBActive {
            Text("層B（入力イベント模擬）動作中")
        }
        if let message = appState.message {
            Text(message)
        }

        Divider()

        // 既定の選択肢（1時間）をワンクリックで。
        Button(quickStartTitle) {
            controller.start(preset: .default)
        }
        .keyboardShortcut("e")

        Menu("有効化") {
            ForEach(KeepAwakePreset.allCases, id: \.self) { preset in
                Button(preset.menuTitle) {
                    activate(preset)
                }
            }
            Divider()
            Button("時刻を指定して停止…") {
                AppEnvironment.shared.showStopTimePicker()
            }
        }

        Button("停止") {
            controller.stop(reason: .userRequested)
        }
        .disabled(!appState.isActive)
        .keyboardShortcut("s")

        Divider()

        Button("設定…") {
            AppEnvironment.shared.showSettings()
        }
        .keyboardShortcut(",")

        Button("StayAwake を終了") {
            AppEnvironment.shared.terminate(reason: .appTerminating)
        }
        .keyboardShortcut("q")
    }

    private func activate(_ preset: KeepAwakePreset) {
        if preset.isIndefinite {
            // 無期限は選択のたびに一度確認する。
            guard Dialogs.confirmIndefinite() else { return }
        }
        controller.start(preset: preset)
    }
}
