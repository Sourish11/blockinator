// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IGBlock",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "IGBlock", targets: ["IGBlock"]),
    ],
    dependencies: [
        .package(path: "../IGBlockCore"),
    ],
    targets: [
        .target(
            name: "IGBlock",
            dependencies: ["IGBlockCore"],
            resources: [.copy("route_shim.js")]
        ),
    ]
)
