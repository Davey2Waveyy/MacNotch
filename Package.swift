// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacNotch",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "MacNotchKit",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
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
