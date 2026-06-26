// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "GenerateCopy",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Dev",
            targets: ["Dev"]
        ),
    ],
    targets: [
        .target(
            name: "Dev",
            path: "Dev",
            exclude: [
                "DevApp.swift",
                "Assets.xcassets",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
