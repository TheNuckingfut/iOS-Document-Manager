// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "DocumentManager",
    products: [
        .executable(
            name: "DocumentManager",
            targets: ["DocumentManager"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DocumentManager",
            dependencies: [],
            path: "Sources"
        ),
    ]
)