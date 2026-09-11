#!/usr/bin/env bash
# StayAwake.app バンドルを組み立てる。
#
#   1. swift build（既定: release）
#   2. build/StayAwake.app/Contents/{MacOS,Resources} を作成
#   3. 実行ファイルと Info.plist をコピー
#   4. ad-hoc 署名（codesign --sign -）
#
# 環境変数:
#   CONFIG=debug|release   ビルド構成（既定: release）
#   OUT_DIR=<path>         出力先ディレクトリ（既定: <repo>/build）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="StayAwake"
CONFIG="${CONFIG:-release}"
OUT_DIR="${OUT_DIR:-$ROOT/build}"
APP="$OUT_DIR/$APP_NAME.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this script must run on macOS (found $(uname -s))" >&2
  exit 1
fi

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG" --package-path "$ROOT"

BIN_DIR="$(swift build -c "$CONFIG" --package-path "$ROOT" --show-bin-path)"
BIN="$BIN_DIR/$APP_NAME"
if [[ ! -x "$BIN" ]]; then
  echo "error: built binary not found at $BIN" >&2
  exit 1
fi

echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> codesign (ad-hoc)"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=1 "$APP" || true

echo "==> done: $APP"
echo "    run:  open \"$APP\""
