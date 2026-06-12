// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LidAngleApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LidAngleApp", targets: ["LidAngleApp"])
    ],
    targets: [
        .executableTarget(
            name: "LidAngleApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
