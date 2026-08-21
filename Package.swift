// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDReader",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "MarkdownCore", targets: ["MarkdownCore"]),
        .executable(name: "MDReader", targets: ["MDReader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "MarkdownCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .executableTarget(
            name: "MDReader",
            dependencies: ["MarkdownCore"]
        ),
        .testTarget(
            name: "MarkdownCoreTests",
            dependencies: ["MarkdownCore"]
        ),
    ]
)
