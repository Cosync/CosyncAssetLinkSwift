// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CosyncAssetLinkSwift",
    platforms: [
            .macOS(.v10_15), .iOS("15.0"), .tvOS(.v13)
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CosyncAssetLinkSwift",
            targets: ["CosyncAssetLinkSwift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/realm/realm-swift",
            from: "10.50.0"
        ),
        .package(
            url: "https://github.com/apple/swift-log.git",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "1.0.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CosyncAssetLinkSwift",
            dependencies: [.product(name: "RealmSwift", package: "realm-swift"),
                       .product(name: "Logging", package: "swift-log"),
                       .product(name: "Collections", package: "swift-collections")
            ]),
        .testTarget(
            name: "CosyncAssetLinkSwiftTests",
            dependencies: ["CosyncAssetLinkSwift"]),
    ]
)
