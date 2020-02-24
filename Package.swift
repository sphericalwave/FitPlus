// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "FitPlus",
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
  targets: [
    .target(
      name: "FitPlus",
      dependencies: ["NIO", "NIOHTTP1"]),
    ]
)

