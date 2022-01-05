// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMidiCenter",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftMidiCenter",
            targets: ["SwiftMidiCenter"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "../SwiftMIDI", from: "1.0.5"),
        .package(url: "../../MoofFoundation", from: "1.1.0"),
        .package(url: "../../UniColor", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftMidiCenter",
            dependencies: ["SwiftMIDI", "MoofFoundation", "UniColor"]),
        .testTarget(
            name: "SwiftMidiCenterTests",
            dependencies: ["SwiftMidiCenter", "MoofFoundation", "UniColor"]),
    ]
)
