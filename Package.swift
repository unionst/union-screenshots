// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "union-screenshots",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "UnionScreenshots",
            targets: ["UnionScreenshots"]
        ),
    ],
    targets: [
        .target(
            name: "UnionScreenshots"
        ),
    ]
)
