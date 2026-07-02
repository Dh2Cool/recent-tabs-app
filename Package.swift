// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SafariRecentTabs",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SafariRecentTabs", targets: ["SafariRecentTabsApp"]),
        .library(name: "SafariRecentTabsCore", targets: ["SafariRecentTabsCore"])
    ],
    targets: [
        .target(name: "SafariRecentTabsCore"),
        .executableTarget(
            name: "SafariRecentTabsApp",
            dependencies: ["SafariRecentTabsCore"]
        ),
        .testTarget(
            name: "SafariRecentTabsTests",
            dependencies: ["SafariRecentTabsCore"]
        )
    ]
)
