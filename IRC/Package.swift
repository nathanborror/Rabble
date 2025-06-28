// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IRC",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "IRC", targets: ["IRC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nathanborror/swift-shared-kit", branch: "main"),
    ],
    targets: [
        .target(name: "IRC", dependencies: [
            .product(name: "SharedKit", package: "swift-shared-kit"),
        ]),
        .testTarget(name: "IRCTests", dependencies: ["IRC"]),
    ]
)
