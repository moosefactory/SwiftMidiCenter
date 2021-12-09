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
        .package(url: "https://github.com/moosefactory/SwiftMIDI.git", from: "1.0.1"),
        .package(url: "/Users/moose/MooseFactory/2021/Frameworks/MoofFoundation", from: "1.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftMidiCenter",
            dependencies: ["SwiftMIDI", "MoofFoundation"]),
        .testTarget(
            name: "SwiftMidiCenterTests",
            dependencies: ["SwiftMidiCenter", "MoofFoundation"]),
    ]
)
