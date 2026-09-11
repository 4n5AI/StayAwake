import SwiftUI

/// 初回起動時の注意画面。「理解しました」で閉じる。設定からいつでも再表示できる。
struct FirstLaunchNoticeView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("ご利用前にお読みください")
                    .font(.title2.bold())
            }

            Text("本アプリは、端末の画面ロック（ディスプレイOFF・スクリーンセーバ）までの時間を一時的に延長します。")

            Text("組織で管理された端末（MDM プロファイル適用端末）では、利用前に情報システム部門など管理部門の許可を得てください。")
                .fontWeight(.semibold)

            Text("本アプリは、ユーザーが意図して有効化した時間だけ画面を維持するものです。離席時のロックを恒久的に無効化するものではありません。離席するときは必ず手動でロック（Ctrl+Cmd+Q）してください。")

            Text("画面ロック・バッテリー低下・指定時間の満了で自動停止します。蓋を閉じたときのスリープは妨げません。")
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("理解しました") {
                    onAcknowledge()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
