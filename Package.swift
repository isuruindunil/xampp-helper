// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XamppHelper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "XamppHelper",
            targets: ["XamppHelper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "XamppHelper",
            path: "Sources/XamppHelper"
        ),
        .testTarget(
            name: "XamppHelperTests",
            dependencies: ["XamppHelper"],
            path: "Tests/XamppHelperTests"
        )
    ]
)
