// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Haze",
    targets: [
        Target(name: "Helpers"),
        Target(name: "Haze", dependencies: ["Helpers"]),
        Target(name: "Executable", dependencies: ["Haze"])
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/console.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/json.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/core.git", majorVersion: 2)
    ]
)
