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
        .package(path: "IRC"),
        .package(url: "https://github.com/nathanborror/swift-shared-kit", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-gen-kit", branch: "main"),
        .package(url: "https://github.com/cezheng/Fuzi", from: "3.1.0"),
    ],
    targets: [
        .target(name: "RabbleKit", dependencies: [
            .product(name: "IRC", package: "IRC"),
            .product(name: "SharedKit", package: "swift-shared-kit"),
            .product(name: "GenKit", package: "swift-gen-kit"),
            .product(name: "Fuzi", package: "Fuzi"),
        ]),
    ]
)
