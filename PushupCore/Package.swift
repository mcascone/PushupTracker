// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PushupCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "PushupCore", targets: ["PushupCore"]),
    ],
    targets: [
        .target(name: "PushupCore"),
        .testTarget(name: "PushupCoreTests", dependencies: ["PushupCore"]),
    ]
)
