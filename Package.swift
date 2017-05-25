// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Ether",
    targets: [
        Target(name: "Helpers"),
        Target(name: "Ether", dependencies: ["Helpers"]),
        Target(name: "Executable", dependencies: ["Ether"])
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/console.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/json.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/core.git", majorVersion: 2)
    ]
)
