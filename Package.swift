// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrevuePackage",
    products: [
        .executable(name: "PrevueCLI", targets: ["PrevueCLI"]),
        .library(name: "PrevuePackage", targets: ["PrevuePackage"]),
    ],
    dependencies: [
        .package(name: "CSV", url: "https://github.com/AriX/CSV.swift.git", branch: "master"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
    ],
    targets: [
        .executableTarget(
            name: "PrevueCLI",
            dependencies: ["PrevuePackage"]),
        .target(
            name: "UVSGSerialData"
        ),
        .target(
            name: "PowerPacker"
        ),
        .target(
            name: "PrevuePackage",
            dependencies: ["UVSGSerialData", "PowerPacker", "CSV", "Yams"]),
        .testTarget(
            name: "PrevuePackageTests",
            dependencies: ["PrevuePackage"]),
    ]
)
