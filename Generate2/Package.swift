// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Generate2",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "Generate2",
            targets: ["Generate2"]
        ),
    ],
    dependencies: [
        // Sibling relative path to the generated Api package.
        .package(path: "../Generated/Api"),
    ],
    targets: [
        .target(
            name: "Generate2",
            dependencies: [
                .product(name: "Api", package: "Api"),
            ],
            path: ".",
            exclude: [
                // App-target-only: standalone @main entry, asset catalog,
                // bundled images/audio, and the Package.swift itself.
                "Generate2App.swift",
                "Assets.xcassets",
                "Generate",
                "Package.swift",
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ],
    swiftLanguageModes: [.v6]
)
