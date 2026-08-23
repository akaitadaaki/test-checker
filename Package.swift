// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TestChecker",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "TestCheckerCore", targets: ["TestCheckerCore"]),
        .executable(name: "TestChecker", targets: ["TestChecker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "TestCheckerCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .executableTarget(
            name: "TestChecker",
            dependencies: ["TestCheckerCore"]
        ),
        .testTarget(
            name: "TestCheckerCoreTests",
            dependencies: ["TestCheckerCore"]
        ),
    ]
)
