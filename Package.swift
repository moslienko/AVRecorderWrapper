// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AVRecorderWrapper",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "AVRecorderWrapper",
            targets: ["AVRecorderWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/moslienko/AppViewUtilits.git", from: "1.2.6")
    ],
    targets: [
        .target(
            name: "AVRecorderWrapper",
            dependencies: ["AppViewUtilits"]
        ),
        .testTarget(
            name: "AVRecorderWrapperTests",
            dependencies: ["AVRecorderWrapper"]),
    ]
)
