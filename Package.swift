// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacNotch",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "MacNotchKit",
            path: "Sources/MacNotchKit"
        ),
        .executableTarget(
            name: "MacNotch",
            dependencies: ["MacNotchKit"],
            path: "Sources/MacNotch"
        ),
        .executableTarget(
            name: "MacNotchTests",
            dependencies: ["MacNotchKit"],
            path: "Sources/MacNotchTests"
        ),
    ]
)
