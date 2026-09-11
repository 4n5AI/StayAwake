import AppKit
import Combine
import StayAwakeCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var accessibilityTrusted = false
    @State private var launchAtLogin = false
    @State private var launchAtLoginMessage: String?

    var body: some View {
        Form {
            layerBSection
            autoStopSection
            startupSection
            otherSection
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .onAppear(perform: refresh)
        // システム設定から戻ってきたタイミングで権限状態を再確認する（ポーリングはしない）。
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
    }

    // MARK: 層B

    private var layerBSection: some View {
        Section {
            Toggle("層Bを有効にする（マウスカーソルを 1px 動かして戻す）", isOn: $settings.layerBEnabled)
                .disabled(!accessibilityTrusted)

            if !accessibilityTrusted {
                VStack(alignment: .leading, spacing: 6) {
                    Label("アクセシビリティ権限がないため、層Bは有効化できません。", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    HStack {
                        Button("権限を要求…") {
                            AccessibilityPermission.requestIfNeeded()
                            refresh()
                        }
                        Button("システム設定を開く") {
                            AccessibilityPermission.openSystemSettings()
                        }
                    }
                    Text(AccessibilityPermission.managedDeviceNotice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("アクセシビリティ権限: 付与済み", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }

            LabeledContent("送信間隔") {
                HStack {
                    Slider(
                        value: $settings.layerBInterval,
                        in: SettingsDefaults.layerBIntervalRange,
                        step: 5
                    )
                    Text("\(Int(settings.layerBInterval))秒")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
            }

            LabeledContent("実操作とみなす閾値") {
                HStack {
                    Slider(
                        value: $settings.realInputThreshold,
                        in: SettingsDefaults.realInputThresholdRange,
                        step: 5
                    )
                    Text("\(Int(settings.realInputThreshold))秒")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
            }

            Text("直近この秒数以内に実際の操作があった場合、イベントは送りません。クリックやキー入力は一切生成しません。層A（電源アサーション）だけで足りる環境では層Bは不要です。")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("層B: 入力イベント模擬（オプション）")
        }
    }

    // MARK: 自動停止

    private var autoStopSection: some View {
        Section {
            // `%` を含むため LocalizedStringKey ではなく String で渡す。
            Toggle(lowBatteryTitle, isOn: $settings.stopOnLowBattery)
            Text("画面ロックの検知、指定時間の満了、ログアウト・アプリ終了時は設定に関わらず常に停止します。")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("自動停止")
        }
    }

    private var lowBatteryTitle: String {
        "バッテリー駆動で残量 \(SettingsDefaults.lowBatteryThresholdPercent)% 未満になったら停止する"
    }

    // MARK: 起動

    private var startupSection: some View {
        Section {
            Toggle("ログイン時に起動", isOn: launchAtLoginBinding)
                .disabled(!LaunchAtLogin.isAvailable)
            if !LaunchAtLogin.isAvailable {
                Text(".app バンドルとして起動した場合のみ設定できます（make run）。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let message = launchAtLoginMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("起動")
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { newValue in
                do {
                    try LaunchAtLogin.setEnabled(newValue)
                    launchAtLoginMessage = LaunchAtLogin.requiresApproval
                        ? "システム設定 › 一般 › ログイン項目 で承認が必要です。"
                        : nil
                } catch {
                    launchAtLoginMessage = "設定できませんでした: \(error.localizedDescription)"
                }
                launchAtLogin = LaunchAtLogin.isEnabled
            }
        )
    }

    // MARK: その他

    private var otherSection: some View {
        Section {
            Button("初回起動時の注意を再表示") {
                AppEnvironment.shared.showFirstLaunchNotice()
            }
            LabeledContent("バージョン", value: versionText)
            Text("本アプリはネットワーク通信を行いません。MDM プロファイルや pmset の設定は変更しません。")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("その他")
        }
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "dev"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }

    private func refresh() {
        accessibilityTrusted = AccessibilityPermission.isTrusted()
        launchAtLogin = LaunchAtLogin.isEnabled
    }
}
