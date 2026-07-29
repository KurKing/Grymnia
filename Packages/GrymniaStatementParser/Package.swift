// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GrymniaStatementParser",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GrymniaStatementParser",
            targets: ["GrymniaStatementParser"]
        )
    ],
    targets: [
        .target(
            name: "GrymniaStatementParser"
        ),
        .testTarget(
            name: "GrymniaStatementParserTests",
            dependencies: ["GrymniaStatementParser"]
        )
    ]
)
