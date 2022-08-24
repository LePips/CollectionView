// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CollectionView",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "CollectionView",
            targets: ["CollectionView"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CollectionView",
            dependencies: [])
    ]
)
