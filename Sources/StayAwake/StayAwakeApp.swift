import AppKit
import StayAwakeCore
import SwiftUI

@main
struct StayAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private var env: AppEnvironment { AppEnvironment.shared }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(env.appState)
                .environmentObject(env.settings)
                .environmentObject(env.controller)
        } label: {
            MenuBarLabel()
                .environmentObject(env.appState)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Info.plist の LSUIElement=true で Dock には出ないが、`swift run` 直実行時にも
        // 同じ挙動になるようアクセサリに設定しておく。
        NSApplication.shared.setActivationPolicy(.accessory)
        AppEnvironment.shared.bootstrap()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppEnvironment.shared.controller.stop(reason: .appTerminating)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
