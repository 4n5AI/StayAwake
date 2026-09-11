// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "StayAwake",
    platforms: [
        .macOS(.v13),
    ],
    targets: [
        // UI や IOKit に依存しない純ロジック。ユニットテストの対象。
        .target(
            name: "StayAwakeCore",
            path: "Sources/StayAwakeCore"
        ),
        // メニューバーアプリ本体（SwiftUI + AppKit + IOKit）。
        .executableTarget(
            name: "StayAwake",
            dependencies: ["StayAwakeCore"],
            path: "Sources/StayAwake"
        ),
        .testTarget(
            name: "StayAwakeTests",
            dependencies: ["StayAwakeCore"],
            path: "Tests/StayAwakeTests"
        ),
    ]
)
