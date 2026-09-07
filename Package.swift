// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Topsoil",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "TopsoilKit",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/TopsoilKit"
        ),
        .executableTarget(
            name: "Topsoil",
            dependencies: ["TopsoilKit"],
            path: "Sources/Topsoil"
        ),
        .executableTarget(
            name: "TopsoilTests",
            dependencies: ["TopsoilKit"],
            path: "Sources/TopsoilTests"
        ),
        .executableTarget(
            name: "TopsoilSnapshots",
            dependencies: ["TopsoilKit"],
            path: "Sources/TopsoilSnapshots"
        ),
    ]
)
