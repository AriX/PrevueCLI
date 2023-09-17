// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrevuePackage",
    products: [
        .executable(name: "PrevueCLI", targets: ["PrevueCLI"]),
        .library(name: "PrevuePackage", targets: ["PrevuePackage"]),
        .library(name: "UVSGSerialData", targets: ["UVSGSerialData"]),
        .library(name: "PowerPacker", targets: ["PowerPacker"]),
        .library(name: "CFByteOrder", targets: ["CFByteOrder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AriX/CSV.swift.git", branch: "master"),
        .package(url: "https://github.com/AriX/Progress.swift", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/stefanspringer1/SwiftXMLParser.git", from: "1.1.123"),
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
            name: "CFByteOrder"
        ),
        .target(
            name: "PrevuePackage",
            dependencies: ["UVSGSerialData", "PowerPacker", "Yams", "CFByteOrder", "SwiftXMLParser", .product(name: "Progress", package: "Progress.swift"), .product(name: "CSV", package: "CSV.swift")]),
        .testTarget(
            name: "PrevuePackageTests",
            dependencies: ["PrevuePackage"]),
    ]
)
