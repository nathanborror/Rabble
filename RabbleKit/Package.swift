// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RabbleKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "RabbleKit", targets: ["RabbleKit"]),
    ],
    targets: [
        .target(name: "RabbleKit"),
    ]
)
