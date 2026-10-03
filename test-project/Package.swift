// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test-project",
    dependencies: [
        // 0.4 adds sd-bus APIs that Amazon Linux 2's libsystemd does not provide.
        .package(url: "https://github.com/xtremekforever/swift-systemd.git", "0.3.0"..<"0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "hello-world",
            dependencies: [.product(name: "Systemd", package: "swift-systemd")]
        ),
        .testTarget(name: "Tests"),
    ]
)
