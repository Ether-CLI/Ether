// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Ether",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/console.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
        .package(url: "https://github.com/Ether-CLI/Manifest.git", from: "0.1.0")
    ],
    targets: [
        .target(name: "Helpers", dependencies: ["Core", "Console"]),
        .target(name: "Ether", dependencies: ["Helpers", "Console", "Command", "Manifest", "Core"]),
        .target(name: "Executable", dependencies: ["Vapor", "Ether", "Console"])
    ]
)
