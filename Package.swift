// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pigeon",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "Pigeon",
            targets: ["Pigeon"]
        )
    ],
    targets: [
        .target(name: "Pigeon", path: "Pigeon/Classes")
    ],
    swiftLanguageVersions: [.v5]
)
