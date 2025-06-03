// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Events",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Events", targets: ["Events"]),
        .library(name: "EventsCore", targets: ["EventsCore"]),
        .library(name: "EventsMemoryDriver", targets: ["EventsMemoryDriver"]),
        .library(name: "EventsNATSDriver", targets: ["EventsNATSDriver"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.1"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.19.0"),
        //.package(url: "https://github.com/nats-io/nats.swift.git", from: "0.1.0"),
        .package(
            url: "https://github.com/benbenbenbenbenben/nats.swift.git",
            branch: "main"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Events",
            dependencies: [
                "EventsCore"
            ]
        ),
        .target(
            name: "EventsCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AsyncKit", package: "async-kit"),
            ]
        ),
        .target(
            name: "EventsMemoryDriver",
            dependencies: [
                "EventsCore"
            ]
        ),
        .target(
            name: "EventsNATSDriver",
            dependencies: [
                "EventsCore",
                .product(name: "Nats", package: "nats.swift"),
            ]
        ),
        .testTarget(
            name: "EventsTests",
            dependencies: [
                "Events",
                "EventsCore",
                "EventsMemoryDriver",
                "EventsNATSDriver"
            ]
        ),
    ]
)
