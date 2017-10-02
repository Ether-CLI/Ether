// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Ether",
    dependencies: [
        .package(url: "https://github.com/vapor/console.git", from: "2.2.0"),
        .package(url: "https://github.com/vapor/json.git", from: "2.2.0"),
        .package(url: "https://github.com/vapor/core.git", from: "2.1.2")
    ],
    targets: [
        .target(name: "Helpers", dependencies: ["Core"]),
        .target(name: "Ether", dependencies: ["Helpers", "Console"]),
        .target(name: "Executable", dependencies: ["Ether"])
    ]
)
