// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlowGraphSVGConverter",
    dependencies: [
        .package(url: "https://github.com/objective-audio/FlowGraphDotConverter.git", from: "0.2.1"),
        ],
    targets: [
        .target(
            name: "FlowGraphSVGConverter",
            dependencies: ["FlowGraphDotConverterCore"]),
        ]
)
