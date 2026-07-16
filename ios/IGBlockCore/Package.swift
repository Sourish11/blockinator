// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IGBlockCore",
    products: [
        .library(name: "IGBlockCore", targets: ["IGBlockCore"]),
    ],
    targets: [
        .target(name: "IGBlockCore"),
        .testTarget(name: "IGBlockCoreTests", dependencies: ["IGBlockCore"]),
    ]
)
