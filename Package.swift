// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ClipboardHistoryApp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ClipboardHistoryApp",
            targets: ["ClipboardHistoryApp"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClipboardHistoryApp",
            dependencies: [],
            path: "Sources/ClipboardHistoryApp"
        ),
        .testTarget(
            name: "ClipboardHistoryAppTests",
            dependencies: ["ClipboardHistoryApp"]
        )
    ]
)