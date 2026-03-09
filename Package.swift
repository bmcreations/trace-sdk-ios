// swift-tools-version: 5.9
import PackageDescription

let version = "0.7.2"
let checksum = "7dbe68b9a0e3b6c8eb6a14b899b42a36fcc2bdc1c7dc9105c5618873ef8d88d6"

let package = Package(
    name: "TraceSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TraceSDK", targets: ["TraceSDK", "TraceKMP"])
    ],
    targets: [
        .target(name: "TraceSDK", dependencies: ["TraceKMP"], path: "Sources"),
        .binaryTarget(
  name: "TraceKMP",
  url: "https://github.com/bmcreations/trace-sdk-ios/releases/download/\(version)/TraceKMP.xcframework.zip",
  checksum: checksum
        )
    ]
)
