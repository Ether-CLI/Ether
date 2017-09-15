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
        .Package(url: "https://github.com/vapor/console.git", Version(2,2,0)),
        .Package(url: "https://github.com/vapor/json.git", Version(2,2,0)),
        .Package(url: "https://github.com/vapor/core.git", Version(2,1,2))
    ]
)
