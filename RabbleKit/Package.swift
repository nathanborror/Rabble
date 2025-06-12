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
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.0.0"),
        .package(url: "https://github.com/SwiftNIOExtras/swift-nio-irc", from: "0.8.0"),
    ],
    targets: [
        .target(name: "RabbleKit", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
            .product(name: "NIOIRC", package: "swift-nio-irc"),
        ]),
    ]
)
