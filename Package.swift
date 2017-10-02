// swift-tools-version:4.0

import PackageDescription

Package(
    name: "Ether",
    targets: [
        .target(name: "Helpers"),
        .target(name: "Ether", dependencies: ["Helpers"]),
        .target(name: "Executable", dependencies: ["Ether"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/console.git", from: "2.2.0"),
        .package(url: "https://github.com/vapor/json.git", from: "2.2.0"),
        .package(url: "https://github.com/vapor/core.git", from: "2.1.2")
    ]
)
