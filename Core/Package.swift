// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoCullCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PhotoCullCore", targets: ["PhotoCullCore"])
    ],
    targets: [
        .target(name: "PhotoCullCore"),
        .testTarget(name: "PhotoCullCoreTests", dependencies: ["PhotoCullCore"])
    ]
)
