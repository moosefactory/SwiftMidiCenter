// swift-tools-version: 5.9
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
        .package(url: "https://github.com/moosefactory/SwiftMIDI.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/moosefactory/MFFoundation.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/moosefactory/UniColor.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftMidiCenter",
            dependencies: ["SwiftMIDI", "MFFoundation", "UniColor"]),
        .testTarget(
            name: "SwiftMidiCenterTests",
            dependencies: ["SwiftMidiCenter"]),
    ]
)
