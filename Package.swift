// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SleepGuard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SleepGuard", targets: ["SleepGuard"]),
        .executable(name: "SleepGuardOverlay", targets: ["SleepGuardOverlay"])
    ],
    targets: [
        .target(
            name: "SleepGuardCore",
            resources: [
                .copy("Resources/LaunchAgents/com.faka.sleepguard.overlay.plist")
            ]
        ),
        .executableTarget(
            name: "SleepGuard",
            dependencies: ["SleepGuardCore"]
        ),
        .executableTarget(
            name: "SleepGuardOverlay",
            dependencies: ["SleepGuardCore"]
        ),
        .testTarget(
            name: "SleepGuardCoreTests",
            dependencies: ["SleepGuardCore"],
            resources: [
                .copy("Resources/com.faka.sleepguard.overlay.plist")
            ]
        )
    ]
)
