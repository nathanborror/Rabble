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
    dependencies: [
        .package(url: "https://github.com/nathanborror/swift-shared-kit", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-irc", branch: "main"),
    ],
    targets: [
        .target(name: "RabbleKit", dependencies: [
            .product(name: "SharedKit", package: "swift-shared-kit"),
            .product(name: "IRC", package: "swift-irc"),
        ]),
    ]
)
