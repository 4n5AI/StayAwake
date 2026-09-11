# StayAwake（仮称）

macOS 用メニューバーアプリ。**ユーザーが意図して有効化した時間だけ**ディスプレイの自動OFF／スクリーンセーバを抑止します。
MDM プロファイルの変更・回避は行いません。離席時のロックを恒久的に無効化するものでもありません。

> **利用前に**: 組織で管理された端末では、情報システム部門など管理部門の許可を得てから利用してください。初回起動時に同趣旨の注意画面が表示されます。

## ダウンロードして使う（ビルド不要）

ビルド済みの `.app` を [`dist/StayAwake.app.zip`](dist/StayAwake.app.zip) に置いています。

| 項目 | 内容 |
|---|---|
| 対応 | macOS 13 Ventura 以上、Apple Silicon（arm64） |
| 署名 | ad-hoc（開発者IDなし）。初回起動時に Gatekeeper の確認が出ます |
| ソース | このリポジトリのコミット `a84fc09` からビルド |

Intel Mac の場合は後述の「ビルドと起動」からご自身でビルドしてください。

### インストール手順

1. GitHub 上で `dist/StayAwake.app.zip` を開き、「Download」ボタンで保存します。
2. ダウンロードした zip をダブルクリックして展開し、`StayAwake.app` を **アプリケーション** フォルダに移動します。
3. `StayAwake.app` をダブルクリックします。「開発元を検証できないため開けません」と出た場合は次のどちらかを行います。
   - システム設定 › プライバシーとセキュリティ を開き、下部に出る「StayAwake は…」の横の **「このまま開く」** を押す
   - またはターミナルで隔離属性を外す
     ```sh
     xattr -dr com.apple.quarantine /Applications/StayAwake.app
     ```
4. 初回起動時に注意画面が出ます。内容を確認して「理解しました」を押します。
5. 通知の許可を求められたら「許可」を選びます（自動停止を通知で知らせるため）。

Dock にはアイコンが出ません。メニューバー右側の **目のアイコン** が StayAwake です。

### 簡単な使い方

1. メニューバーの目のアイコンをクリックします。
2. **「すぐに有効化（1時間）」** を選ぶと、1時間のあいだ画面が消えなくなります。アイコンが塗りつぶしになり、横に残り時間が表示されます。
3. 時間を変えたいときは **「有効化 ▸」** から 15分〜4時間、無期限、「時刻を指定して停止…」を選びます。有効中に選び直すと上書きされます。
4. やめるときは **「停止」** を選びます。
5. 次のときは自動で停止し、通知が届きます。
   - 指定した時間が経過した／指定した時刻になった
   - 画面をロックした（Ctrl+Cmd+Q など）
   - バッテリー駆動で残量が 15% 未満になった
6. 離席するときは、必ず Ctrl+Cmd+Q で手動ロックしてください。本アプリはロックを妨げません。

層B（マウスカーソルを 1px 動かす方式）は既定でオフです。層Aだけで画面が維持できない場合のみ、「設定…」からアクセシビリティ権限を付与してオンにしてください（後述「権限」）。

アンインストールは `StayAwake.app` をゴミ箱に入れるだけです。設定を消すには `defaults delete com.local.stayawake` を実行します。

## ライセンス・免責

- 本ソフトウェアは **自己責任で自由に使用・複製・改変・再配布できます**。
- 現状有姿（AS IS）で提供され、いかなる保証もありません。本ソフトウェアの使用によって生じた損害について、作者は一切の責任を負いません。
- 組織で管理された端末で使う場合は、利用前に管理部門の許可を得てください。管理ポリシーへの適合はご自身の責任で確認してください。

## 方式

| 層 | 方式 | 既定 | 概要 |
|---|---|---|---|
| A | 電源アサーション | 常時ON | `IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleDisplaySleep)` ＋ 30秒ごとの `IOPMAssertionDeclareUserActivity`。OS 公式 API。`PreventSystemSleep` は使わないので蓋を閉じればスリープします。 |
| B | 入力イベント模擬 | OFF | 直近に実操作がないときだけ、マウスカーソルを +1px 動かして即座に戻す `mouseMoved` を `CGEventPost`。クリック・キー入力は生成しません。アクセシビリティ権限が必要。 |

層Aで足りる環境では層Bは不要です。層Bは設定画面で明示的にオンにした場合のみ動作します。

## 要件

- macOS 13 Ventura 以上
- Xcode 15 以上（Swift 5.9 以上）のコマンドラインツール
- 外部ライブラリなし・ネットワーク通信なし

## ビルドと起動

```sh
make app      # swift build -c release → build/StayAwake.app を組み立て → ad-hoc 署名
make run      # 既存プロセスを止めて .app を起動
make stop     # SIGTERM で終了（アサーションが解放されることを確認できる）
make test     # ユニットテスト（StayAwakeCore）
make clean
```

補助ターゲット:

```sh
make assertions   # pmset -g assertions から本アプリのアサーションを表示
make logs         # log stream --predicate 'subsystem == "com.local.stayawake"' --level info
```

`swift run StayAwake` でも起動できますが、`.app` バンドル外では **通知とログイン時起動が使えません**（`UNUserNotificationCenter` はバンドル必須）。動作確認は `make run` を使ってください。

Xcode プロジェクトは不要です。必要なら `open Package.swift` で Xcode から開けます。

## 権限

### アクセシビリティ（層Bのみ）

1. メニュー › 設定… › 「層B: 入力イベント模擬」
2. 「権限を要求…」を押すとシステムのプロンプトが出ます。「システム設定を開く」から  
   システム設定 › プライバシーとセキュリティ › アクセシビリティ で **StayAwake** をオンにします。
3. 設定画面に戻ると権限状態が再確認され、層Bのトグルが有効になります。

権限がない状態では層Bのトグルは無効化され、理由が表示されます。
システム設定でオンにできない（項目が灰色・「管理者によって制限されています」）場合、その端末では管理部門の設定により層Bを利用できません。本アプリはこれを回避しません。

ad-hoc 署名のため、`make app` でビルドし直すとバイナリのハッシュが変わり、アクセシビリティ権限の再付与が必要になることがあります（システム設定で一度オフ→オン）。

### 通知

初回起動時に通知の許可を求めます。自動停止（満了・ロック・バッテリー低下）の際に通知します。

## 使い方

- メニューバーの目のアイコン（停止中: アウトライン、有効中: 塗り＋残り時間）をクリック
- **すぐに有効化（1時間）** … 既定の選択肢
- **有効化 ▸** 15分 / 30分 / 1時間（既定） / 2時間 / 4時間 / 無期限 / 時刻を指定して停止…
  - 有効中に再選択すると時間を上書きします
  - 無期限は選択時に確認ダイアログが出ます
- **停止** … 即時解除
- キーボード: メニューを開いた状態で `E`（1時間で有効化）、`S`（停止）、`,`（設定）、`Q`（終了）

### 自動停止（通知あり）

- 指定時間の満了／指定時刻の到達
- 画面ロックの検知（ロック解除後に自動再開はしません）
- バッテリー駆動かつ残量 15% 未満（設定でオフ可）

### 常に停止（通知なし）

- ログアウト・シャットダウン・アプリ終了（メニュー／`SIGTERM`／`SIGINT`）

## 設定（UserDefaults 標準 suite）

| キー | 既定 | 内容 |
|---|---|---|
| `layerB.enabled` | `false` | 層Bの有効／無効 |
| `layerB.intervalSeconds` | `45` | 層Bの送信間隔（15〜120） |
| `layerB.realInputThresholdSeconds` | `20` | 直近この秒数以内に実操作があればスキップ（5〜120） |
| `autoStop.lowBattery` | `true` | バッテリー低下時の自動停止 |
| `firstLaunchNotice.shown` | `false` | 初回注意画面の表示済みフラグ |

ログイン時起動は `SMAppService.mainApp` を使い、状態はシステム側（システム設定 › 一般 › ログイン項目）が保持します。

設定をリセットするには:

```sh
defaults delete com.local.stayawake
```

## 動作確認手順（フェーズ別）

### Phase 1 — 骨格
1. `make run` → Dock にアイコンが出ず、メニューバーに目のアイコンだけが出る
2. クリックすると「停止中」「すぐに有効化（1時間）」「有効化 ▸」「停止（無効）」「設定…」「StayAwake を終了」が並ぶ
3. 初回はビルド後に注意画面が表示され、「理解しました」で閉じると以降は出ない（設定 › その他 から再表示可）

### Phase 2 — 層A
1. 「有効化 ▸ 15分」→ アイコンが `eye.fill` になり横に「15分」、メニュー先頭が「残り 15分」
2. `make assertions` に `PreventUserIdleDisplaySleep` ＋ `StayAwake: user requested display to stay on` と `UserIsActive`（`StayAwake heartbeat`）が表示される
3. プロファイルのディスプレイOFF時間（例 10分）を超えても画面が維持される
4. 「停止」→ `make assertions` から消える。15分放置すれば満了で停止し通知が届く

### Phase 3 — 自動停止と安全策
1. 有効化中に Ctrl+Cmd+Q でロック → ロック解除後、停止状態になっており通知が届いている（`screenIsLocked` 検知）
2. 有効化中に `make stop`（SIGTERM）→ `make assertions` にアサーションが残らない
3. 有効化中に `kill -9 $(pgrep -x StayAwake)` → `make assertions` にアサーションが残らない（powerd がプロセス単位で回収）
4. バッテリー駆動で残量 15% 未満にすると停止し通知が届く（設定でオフにすると停止しない）
5. 蓋を閉じるとスリープする（システムスリープは妨げない）

### Phase 4 — 層B
1. 設定 › 層B: 権限がない状態ではトグルが無効で理由が表示される
2. 権限を付与 → トグルが有効になる → オン
3. 有効化し `make logs` を眺める。マウスやキーボードを操作している間は  
   `skip: real user input Ns ago` が出て、手を離して 20 秒以上経つと `posted synthetic mouseMoved` が出る
4. 層Aだけではスクリーンセーバが起動する環境で、層Bをオンにすると起動しない
5. ロック中は `skip: screen is locked`（通常はロック検知で停止済みのため出ない）

### Phase 5 — 仕上げ
1. `make test` が通る（プリセット、残り時間表示、時刻計算、実操作判定、バッテリー判定、設定範囲）
2. 設定 › 起動 › 「ログイン時に起動」をオン → システム設定 › 一般 › ログイン項目 に StayAwake が現れる
3. 待機時の CPU 使用率が 0.1% 未満（アクティビティモニタ）。層Aは 30秒、層Bは 45秒（既定）間隔のタイマーのみで、ポーリングはしていません
4. ネットワーク接続がない（`lsof -i -a -p $(pgrep -x StayAwake)` が空）

## 受け入れ基準チェックリスト

- [ ] Dock にアイコンが出ず、メニューバーだけに常駐する
- [ ] 「1時間」を選択後、プロファイルの 10分タイマーを超えてもディスプレイが消えない（層Aのみ）
- [ ] `pmset -g assertions` に本アプリのアサーションが表示され、停止後は消える
- [ ] タイマー満了で自動停止し、通知が届く
- [ ] Ctrl+Cmd+Q で手動ロックでき、ロック時に自動停止する
- [ ] 蓋を閉じるとスリープする
- [ ] 層Bはアクセシビリティ権限なしでは有効化できない
- [ ] 層B有効時、実操作中はイベントが発火しない（ログで確認）
- [ ] アプリを強制終了（`kill`）してもアサーションが残らない
- [ ] 待機時 CPU 0.1% 未満、ネットワーク通信なし

## 構成

```
StayAwake/
├── Package.swift
├── Makefile
├── scripts/build_app.sh              # .app バンドル組み立て・ad-hoc 署名
├── Resources/Info.plist              # LSUIElement=true, CFBundleIdentifier=com.local.stayawake
├── dist/StayAwake.app.zip            # ビルド済みバイナリ（Apple Silicon）
├── Sources/StayAwakeCore/            # UI・IOKit 非依存の純ロジック（テスト対象）
│   ├── KeepAwakePreset.swift         # 15分〜無期限のプリセット
│   ├── RemainingTimeFormatter.swift  # 「残り 42分」「∞」
│   ├── StopTimeCalculator.swift      # 時刻指定 → 次の到来時刻
│   ├── IdlePolicy.swift              # IdleMonitoring protocol と発火判定
│   ├── BatteryPolicy.swift           # 15% 未満判定
│   ├── SettingsDefaults.swift        # 既定値・範囲
│   └── StopReason.swift              # 停止理由と通知文言
├── Sources/StayAwake/
│   ├── StayAwakeApp.swift            # @main, MenuBarExtra, AppDelegate
│   ├── AppEnvironment.swift          # 共有オブジェクト・ウィンドウ・シグナル処理
│   ├── AppState.swift                # UI 状態（ObservableObject）
│   ├── KeepAwakeController.swift     # 開始/停止の司令塔（層A・層B・タイマー・自動停止）
│   ├── PowerAssertionManager.swift   # 層A（IOKit）
│   ├── InputSimulator.swift          # 層B（CGEvent）
│   ├── IdleMonitor.swift             # CGEventSource による IdleMonitoring 実装
│   ├── SystemEventObserver.swift     # 画面ロック / スリープ / ログアウト
│   ├── BatteryMonitor.swift          # IOPS 通知による電源監視
│   ├── AccessibilityPermission.swift # AXIsProcessTrusted 周り
│   ├── LaunchAtLogin.swift           # SMAppService
│   ├── Notifier.swift                # UserNotifications
│   ├── WindowPresenter.swift         # SwiftUI ビューを NSWindow で表示
│   ├── Dialogs.swift                 # NSAlert
│   ├── Settings.swift                # AppSettings（UserDefaults ラッパー）
│   ├── Logging.swift
│   └── Views/
│       ├── MenuBarLabel.swift
│       ├── MenuContentView.swift
│       ├── SettingsView.swift
│       ├── FirstLaunchNoticeView.swift
│       └── StopTimePickerView.swift
└── Tests/StayAwakeTests/
    ├── TimerLogicTests.swift
    ├── IdleMonitorTests.swift
    └── PolicyTests.swift
```

推奨構成からの変更点: テスト容易性のため純ロジックを `StayAwakeCore` ライブラリターゲットに分離し、`Settings` は SwiftUI の同名シーンとの衝突を避けて `AppSettings` としています。

## 既知の制約

- MDM の設定によっては層Aだけではスクリーンセーバの起動を抑止できないことがあります。その場合は層Bを使ってください。
- アクセシビリティ権限の付与自体がプロファイルで禁止されている端末では層Bは利用できません。アプリは回避を試みません。
- 層Bの模擬イベント自体も `secondsSinceLastEventType` をリセットします。自前イベントを「実操作」と誤認しないよう、最後に送った時刻との差で判別しています（`IdlePolicy`）。
- ad-hoc 署名のためビルドごとにアクセシビリティ権限の再付与が必要になる場合があります。
- `PreventUserIdleDisplaySleep` は無操作によるディスプレイスリープのみ抑止します。`pmset displaysleepnow` や手動ロックは妨げません（仕様どおり）。
- ログ（`com.local.stayawake`）にはユーザーの入力内容・画面内容・カーソル座標を一切出力しません。

## やらないこと

- MDM プロファイルの削除・改変・回避
- システム設定や `pmset` の永続的な変更（`sudo` を要する操作全般）
- パスワード要求設定（「すぐに」）への干渉
- ネットワーク通信、テレメトリ、外部ライブラリの導入
- クリック／キー入力イベントの生成
