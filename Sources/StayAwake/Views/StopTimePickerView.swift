import StayAwakeCore
import SwiftUI

/// 「時刻を指定して停止」の時刻ピッカー。
struct StopTimePickerView: View {
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void

    /// 初期値は 1 時間後。
    @State private var time: Date = Date().addingTimeInterval(60 * 60)

    private var plannedEnd: Date? {
        let hm = StopTimeCalculator.hourMinute(of: time)
        return StopTimeCalculator.nextOccurrence(hour: hm.hour, minute: hm.minute, after: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("指定した時刻になったら画面の維持を停止します。")

            DatePicker("停止時刻", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.field)

            if let end = plannedEnd {
                Text("停止予定: \(end.formatted(date: .abbreviated, time: .shortened))（\(RemainingTimeFormatter.menuText(isActive: true, endDate: end))）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("キャンセル") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                Button("有効化") {
                    if let end = plannedEnd {
                        onConfirm(end)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(plannedEnd == nil)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
