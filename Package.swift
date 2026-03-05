// swift-tools-version: 5.9
import PackageDescription

let version = "0.4.1"
let checksum = "0a466e20eadd73d976158b43d1817390cfe1e60699c74edc3710a3af8502e819"

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
