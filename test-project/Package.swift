// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test-project",
    dependencies: [
        .package(url: "https://github.com/xtremekforever/swift-systemd.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "hello-world",
            dependencies: [.product(name: "Systemd", package: "swift-systemd")]
        ),
        .testTarget(name: "Tests"),
    ]
)
