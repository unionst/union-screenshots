// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-screenshots",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionScreenshots",
            targets: ["UnionScreenshots"]
        )
    ],
    targets: [
        .target(
            name: "UnionScreenshots"
        )
    ]
)
