APP_NAME  := StayAwake
BUILD_DIR := build
APP       := $(BUILD_DIR)/$(APP_NAME).app
CONFIG    ?= release
SUBSYSTEM := com.local.stayawake

.PHONY: all build app sign run stop test clean assertions logs

all: app

## Swift Package をビルドする（.app は作らない）
build:
	swift build -c $(CONFIG)

## .app バンドルを組み立てて ad-hoc 署名する
app:
	CONFIG=$(CONFIG) ./scripts/build_app.sh

## 署名だけやり直す
sign:
	codesign --force --deep --sign - $(APP)

## 既存プロセスを止めてから .app を起動する
run: app
	-pkill -x $(APP_NAME) 2>/dev/null; sleep 0.5
	open $(APP)

## 起動中の StayAwake を終了する（SIGTERM → アサーション解放を確認できる）
stop:
	-pkill -x $(APP_NAME)

test:
	swift test

clean:
	rm -rf .build $(BUILD_DIR)

## 本アプリが保持している電源アサーションを表示する
assertions:
	pmset -g assertions | grep -i -E 'stayawake|PreventUserIdleDisplaySleep|UserIsActive' || echo "(no StayAwake assertions)"

## 本アプリのログをストリーム表示する（層Bのスキップ/発火はここで確認）
logs:
	log stream --predicate 'subsystem == "$(SUBSYSTEM)"' --level info
